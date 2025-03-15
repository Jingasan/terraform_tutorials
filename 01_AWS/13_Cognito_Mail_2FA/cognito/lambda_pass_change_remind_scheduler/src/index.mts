import { addDays, format } from "date-fns";
import { ScheduledHandler, ScheduledEvent } from "aws-lambda";
import * as SES from "@aws-sdk/client-sesv2";
import * as SecretsManager from "@aws-sdk/client-secrets-manager";
import * as Cognito from "@aws-sdk/client-cognito-identity-provider";
import { TZDate } from "@date-fns/tz";
const REGION = process.env.REGION || "ap-northeast-1";
const FROM_EMAIL_ADDRESS = process.env.SES_EMAIL_FROM || undefined;
const SECRET_NAME = process.env.SECRET_NAME;
const SERVICE_NAME = `[${process.env.SERVICE_NAME}] ` || "";
const cognitoClient = new Cognito.CognitoIdentityProviderClient({
  region: REGION,
});
const sesClient = new SES.SESv2Client({ region: REGION });
const secretsManagerClient = new SecretsManager.SecretsManagerClient({
  region: REGION,
});

/**
 * 日本時刻での日付を取得
 * @param date UNIX時刻
 * @returns 日本時刻での日付(yyyy/MM/dd)
 */
const getJSTDate = (date: Date): string => {
  const jstDate = new TZDate(date, "Asia/Tokyo");
  return format(jstDate, "yyyy-MM-dd");
};

/**
 * SecretsManagerからシークレットおよび設定値を取得する
 * @returns シークレットおよび設定値
 */
const getSecrets = async (): Promise<
  | {
      cognitoUserPoolId: string;
      passwordExpirationDays: number;
      reminderDaysBeforePasswordExpiry: number;
    }
  | undefined
> => {
  if (!SECRET_NAME) {
    console.error("SECRET_NAME is not set");
    return undefined;
  }
  const command = new SecretsManager.GetSecretValueCommand({
    SecretId: SECRET_NAME,
  });
  const res = await secretsManagerClient.send(command);
  if (!res.SecretString) {
    console.error("SecretString is not found");
    return undefined;
  }
  try {
    const secret = JSON.parse(res.SecretString);
    if (
      secret.cognitoUserPoolId === undefined ||
      secret.passwordExpirationDays === undefined ||
      secret.reminderDaysBeforePasswordExpiry === undefined
    ) {
      console.error(
        "cognitoUserPoolId, passwordExpirationDays or reminderDaysBeforeExpiry is not found"
      );
      return undefined;
    }
    return {
      cognitoUserPoolId: secret.cognitoUserPoolId,
      passwordExpirationDays: secret.passwordExpirationDays,
      reminderDaysBeforePasswordExpiry: secret.reminderDaysBeforePasswordExpiry,
    };
  } catch (error) {
    console.error("SecretString is not JSON format");
    return undefined;
  }
};

/**
 * 全ユーザー情報の取得
 * @param userPoolId ユーザープールID
 * @returns 全ユーザー情報
 */
const listAllUsers = async (
  userPoolId: string
): Promise<Cognito.UserType[]> => {
  let users: Cognito.UserType[] = [];
  let paginationToken: string | undefined;
  // ページネーショントークンが存在する限り続ける
  do {
    try {
      // https://docs.aws.amazon.com/AWSJavaScriptSDK/v3/latest/client/cognito-identity-provider/command/ListUsersCommand/
      const command = new Cognito.ListUsersCommand({
        UserPoolId: userPoolId,
        // ListUsersCommandで取得できる上限数は60に限られているため、続きを取得する際には前回のレスポンスのページネーショントークンを指定
        PaginationToken: paginationToken,
      });
      const res = await cognitoClient.send(command);
      if (res.Users) users.push(...res.Users);
      paginationToken = res.PaginationToken;
    } catch (err) {
      console.error((err as Cognito.InternalErrorException).name);
      console.error((err as Cognito.InternalErrorException).message);
      return [];
    }
  } while (paginationToken);
  return users;
};

/**
 * 定刻にパスワード変更依頼メールまたはパスワード有効期限切れ通知メールを送信するハンドラ
 * @param event イベント
 * @returns イベント
 */
export const handler: ScheduledHandler = async (event: ScheduledEvent) => {
  // シークレットおよび設定値を取得
  const secrets = await getSecrets();
  if (!secrets) return;

  // ユーザー情報一覧の取得
  const userList = await listAllUsers(secrets.cognitoUserPoolId);
  console.log(userList);

  // 本日の日付を取得
  const eventTime = new Date(event.time);
  const todayDate = getJSTDate(eventTime);
  console.log("TodayDate: ", todayDate);

  // パスワード有効期限が迫ったユーザーに対し、更新依頼メールを送信
  await Promise.all(
    userList.map(async (user) => {
      const email = user.Attributes?.find(
        (attr) => attr.Name === "email"
      )?.Value;
      const passwordSetDate = user.Attributes?.find(
        (attr) => attr.Name === "custom:password_set_date"
      )?.Value;
      if (!email) {
        console.error(`Email not found for user: ${user.Username}`);
        return;
      }
      if (!passwordSetDate) {
        console.log(`Password set date not found for user: ${user.Username}`);
        return;
      }

      /** 本日(ミリ秒換算) */
      const todayDateMS = new Date(todayDate).getTime();
      /** パスワード設定日(ミリ秒換算) */
      const passwordSetDateMS = new Date(passwordSetDate).getTime();
      /** パスワード有効期限日(ミリ秒換算) */
      const expiryDateMS =
        passwordSetDateMS +
        secrets.passwordExpirationDays * 24 * 60 * 60 * 1000;
      /** パスワード有効期限切れ通知日(ミリ秒換算) */
      const expiredNotificationDateMS = expiryDateMS + 1 * 24 * 60 * 60 * 1000;
      /** パスワード更新依頼通知開始日(ミリ秒換算) */
      const reminderStartDateMS =
        expiredNotificationDateMS -
        secrets.reminderDaysBeforePasswordExpiry * 24 * 60 * 60 * 1000;

      console.log("Email: ", email);
      console.log("passwordSetDateMS: ", passwordSetDateMS);
      console.log("expiryDateMS: ", expiryDateMS);
      console.log("expiredNotificationDateMS: ", expiredNotificationDateMS);
      console.log("reminderStartDateMS: ", reminderStartDateMS);
      console.log("todayDateMS: ", todayDateMS);

      // 期限7日前〜当日までパスワード更新依頼メールを送信
      if (reminderStartDateMS <= todayDateMS && todayDateMS <= expiryDateMS) {
        // パスワード有効期限日(日本時刻yyyy/MM/dd)
        const ExpiryDate = format(
          addDays(new Date(passwordSetDate), secrets.passwordExpirationDays),
          "yyyy/MM/dd"
        );
        // メール内容
        const mailSub = `${SERVICE_NAME} パスワード更新のお願い`;
        const mailBody = `${email} 様<br/><br/>
いつもご利用いただき、ありがとうございます。<br/>
現在のパスワードの有効期限は ${ExpiryDate} までです。<br/>
有効期限が切れると、現在のパスワードでサービスにログインできなくなります。<br/>
サービスにログインし、パスワードを更新してください。`;
        // メール送信
        await sesClient.send(
          new SES.SendEmailCommand({
            FromEmailAddress: FROM_EMAIL_ADDRESS,
            Destination: { ToAddresses: [email] },
            Content: {
              Simple: {
                Subject: { Data: mailSub },
                Body: { Html: { Data: mailBody } },
              },
            },
          })
        );
        console.log("Password update request email sent to: ", email);
      }

      // パスワード有効期限日翌日に有効期限切れの通知メールを送信
      if (todayDateMS === expiredNotificationDateMS) {
        // メール内容
        const mailSub = `${SERVICE_NAME} パスワードの有効期限が切れました`;
        const mailBody = `${email} 様<br/><br/>
いつもご利用いただき、ありがとうございます。<br/>
パスワードの有効期限が切れました。<br/>
パスワードリセットしてください。`;
        // メール送信
        await sesClient.send(
          new SES.SendEmailCommand({
            FromEmailAddress: FROM_EMAIL_ADDRESS,
            Destination: { ToAddresses: [email] },
            Content: {
              Simple: {
                Subject: { Data: mailSub },
                Body: { Html: { Data: mailBody } },
              },
            },
          })
        );
        console.log("Password expiration notification email sent to: ", email);
      }
    })
  );
};
