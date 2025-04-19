/**
 * パスワード期限切れが近いユーザーに対し、パスワード変更依頼メールを送信するLambda
 */
import * as sourceMapSupport from "source-map-support";
import { addDays, format } from "date-fns";
import { ScheduledHandler, ScheduledEvent } from "aws-lambda";
import * as SES from "@aws-sdk/client-sesv2";
import * as SecretsManager from "@aws-sdk/client-secrets-manager";
import * as Cognito from "@aws-sdk/client-cognito-identity-provider";
import { Logger } from "@aws-lambda-powertools/logger";
import { TZDate } from "@date-fns/tz";
sourceMapSupport.install();
const REGION = process.env.REGION || "ap-northeast-1";
const FROM_EMAIL_ADDRESS = process.env.SES_EMAIL_FROM || undefined;
const SECRET_NAME = process.env.SECRET_NAME;
const SERVICE_NAME = process.env.SERVICE_NAME;
const logger = new Logger({ serviceName: SERVICE_NAME });
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
    }
  | undefined
> => {
  if (!SECRET_NAME) {
    logger.error("SECRET_NAME is not set");
    return undefined;
  }
  const command = new SecretsManager.GetSecretValueCommand({
    SecretId: SECRET_NAME,
  });
  const res = await secretsManagerClient.send(command);
  if (!res.SecretString) {
    logger.error("SecretString is not found");
    return undefined;
  }
  try {
    const secret = JSON.parse(res.SecretString);
    if (
      secret.cognitoUserPoolId === undefined ||
      secret.passwordExpirationDays === undefined
    ) {
      logger.error("cognitoUserPoolId or passwordExpirationDays is not found");
      return undefined;
    }
    return {
      cognitoUserPoolId: secret.cognitoUserPoolId,
      passwordExpirationDays: secret.passwordExpirationDays,
    };
  } catch (error) {
    logger.error("SecretString is not JSON format");
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
      logger.error((err as Cognito.InternalErrorException).name);
      logger.error((err as Cognito.InternalErrorException).message);
      return [];
    }
  } while (paginationToken);
  return users;
};

/**
 * メールの送信
 * @param fromEmail 送信元メールアドレス
 * @param toEmails 送信先メールアドレス
 * @param mailSub メールタイトル
 * @param mailBody メールボディ
 */
const sendMail = async (
  fromEmail: string,
  toEmails: string[],
  mailSub: string,
  mailBody: string
): Promise<boolean> => {
  try {
    await sesClient.send(
      new SES.SendEmailCommand({
        FromEmailAddress: fromEmail,
        Destination: { ToAddresses: toEmails },
        Content: {
          Simple: {
            Subject: { Data: mailSub },
            Body: { Html: { Data: mailBody } },
          },
        },
      })
    );
    return true;
  } catch (err) {
    logger.error(`Failed to send email to ${toEmails}`, err);
    return false;
  }
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
  logger.info(JSON.stringify(userList, null, 2));

  // 本日の日付を取得
  const eventTime = new Date(event.time);
  const todayDate = getJSTDate(eventTime);
  logger.info(`TodayDate: ${todayDate}`);

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
        logger.error(`Email not found for user: ${user.Username}`);
        return;
      }
      if (!passwordSetDate) {
        logger.info(`Password set date not found for user: ${user.Username}`);
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
      /** パスワード有効期限切れ7日前(ミリ秒換算) */
      const reminder7daysAgoDateMS =
        expiredNotificationDateMS - 7 * 24 * 60 * 60 * 1000;

      logger.info(`email: ${email}`);
      logger.info(`passwordSetDateMS: ${passwordSetDateMS}`);
      logger.info(`expiryDateMS: ${expiryDateMS}`);
      logger.info(`expiredNotificationDateMS: ${expiredNotificationDateMS}`);
      logger.info(`reminder7daysAgoDateMS: ${reminder7daysAgoDateMS}`);
      logger.info(`todayDateMS: ${todayDateMS}`);

      if (
        // パスワード有効期限切れ7日前にパスワード更新依頼メールを送信
        todayDateMS === reminder7daysAgoDateMS
      ) {
        // パスワード有効期限日(日本時刻yyyy/MM/dd)
        const expiryDate = format(
          addDays(new Date(passwordSetDate), secrets.passwordExpirationDays),
          "yyyy/MM/dd"
        );
        // メール内容
        const mailSub = `${SERVICE_NAME} パスワード更新のお願い`;
        const mailBody = `${email} 様<br/><br/>
いつもご利用いただき、ありがとうございます。<br/>
現在のパスワードの有効期限は ${expiryDate} までです。<br/>
有効期限が切れると、現在のパスワードでサービスにログインできなくなります。<br/>
サービスにログインし、パスワードを更新してください。`;
        // メール送信
        await sendMail(FROM_EMAIL_ADDRESS, [email], mailSub, mailBody);
        logger.info(
          `7 days ago password update request email sent to: ${email}`
        );
      } else if (
        // パスワード有効期限日にパスワード更新依頼メールを送信
        todayDateMS === expiryDateMS
      ) {
        // メール内容
        const mailSub = `${SERVICE_NAME} パスワード更新のお願い`;
        const mailBody = `${email} 様<br/><br/>
いつもご利用いただき、ありがとうございます。<br/>
現在のパスワードの有効期限が本日で切れます。<br/>
有効期限が切れると、現在のパスワードでサービスにログインできなくなります。<br/>
サービスにログインし、パスワードを更新してください。`;
        // メール送信
        await sendMail(FROM_EMAIL_ADDRESS, [email], mailSub, mailBody);
        logger.info(
          `1 day ago Password update request email sent to: ${email}`
        );
      } else if (
        // パスワード有効期限日翌日に有効期限切れの通知メールを送信
        todayDateMS === expiredNotificationDateMS
      ) {
        // メール内容
        const mailSub = `${SERVICE_NAME} パスワードの有効期限が切れました`;
        const mailBody = `${email} 様<br/><br/>
いつもご利用いただき、ありがとうございます。<br/>
パスワードの有効期限が切れました。<br/>
サービスのトップページからパスワードをリセットしてください。`;
        // メール送信
        await sendMail(FROM_EMAIL_ADDRESS, [email], mailSub, mailBody);
        logger.info(`Password expiration notification email sent to: ${email}`);
      }
    })
  );
};
