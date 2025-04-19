/**
 * 利用終了日になったことをメール通知するLambda
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
  { cognitoUserPoolId: string } | undefined
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
    if (secret.cognitoUserPoolId === undefined) {
      logger.error("cognitoUserPoolId is not found");
      return undefined;
    }
    return {
      cognitoUserPoolId: secret.cognitoUserPoolId,
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
 * 定刻に利用終了日になったことをメール通知するハンドラ
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
      const usageEndDate = user.Attributes?.find(
        (attr) => attr.Name === "custom:usage_end_date"
      )?.Value;
      if (!usageEndDate) {
        logger.info(`Usage end date not found for user: ${user.Username}`);
        return;
      }

      /** 本日(ミリ秒換算) */
      const todayDateMS = new Date(todayDate).getTime();
      /** 利用終了日(ミリ秒換算) */
      const usageEndDateMS = new Date(usageEndDate).getTime();
      // 利用終了日になったら通知メールを送信
      if (todayDateMS === usageEndDateMS) {
        const email = user.Attributes?.find(
          (attr) => attr.Name === "email"
        )?.Value;
        if (!email) {
          logger.error(`Email not found for user: ${user.Username}`);
          return;
        }
        // メール内容
        const mailSub = `${SERVICE_NAME} サービスご利用可能期間の終了のお知らせ`;
        const mailBody = `${email} 様<br/><br/>
いつもご利用いただき、ありがとうございます。<br/>
お客様のサービスご利用可能期間が最終日となりましたので、ご連絡いたします。<br/>
利用期間の終了に伴い、明日以降お客様のアカウントで本サービスにはログインできなくなります。<br/>
本サービスをご利用いただき、誠にありがとうございました。`;
        // メール送信
        await sendMail(FROM_EMAIL_ADDRESS, [email], mailSub, mailBody);
        logger.info(`Usage period end reminder email to ${email}`);
      }
    })
  );
};
