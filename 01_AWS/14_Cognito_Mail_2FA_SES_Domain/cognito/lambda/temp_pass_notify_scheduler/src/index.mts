/**
 * 利用開始日になったユーザーに対し、仮パスワードを記載したメールを送信するLambda
 */
import * as sourceMapSupport from "source-map-support";
import { format } from "date-fns";
import { ScheduledHandler, ScheduledEvent } from "aws-lambda";
import * as SecretsManager from "@aws-sdk/client-secrets-manager";
import * as Cognito from "@aws-sdk/client-cognito-identity-provider";
import { Logger } from "@aws-lambda-powertools/logger";
import { TZDate } from "@date-fns/tz";
sourceMapSupport.install();
const REGION = process.env.REGION || "ap-northeast-1";
const SECRET_NAME = process.env.SECRET_NAME;
const SERVICE_NAME = process.env.SERVICE_NAME;
const logger = new Logger({ serviceName: SERVICE_NAME });
const cognitoClient = new Cognito.CognitoIdentityProviderClient({
  region: REGION,
});
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
 * 仮パスワード記載メールの送信
 * @param cognitoUserPoolId ユーザープールID
 * @param username ユーザー名
 * @returns ユーザー情報/false:失敗
 */
const sendTemporaryPasswordEmail = async (
  cognitoUserPoolId: string,
  username: string
): Promise<{
  res: Cognito.AdminCreateUserCommandOutput | false;
  error?: Cognito.InternalErrorException;
}> => {
  try {
    // https://docs.aws.amazon.com/AWSJavaScriptSDK/v3/latest/client/cognito-identity-provider/command/AdminCreateUserCommand/
    const command = new Cognito.AdminCreateUserCommand({
      UserPoolId: cognitoUserPoolId,
      Username: username,
      // 一時パスワードの送信方法(EMAIL/SMS)
      DesiredDeliveryMediums: ["EMAIL"],
      // 指定すると固定の一時パスワードを生成
      TemporaryPassword: undefined,
      // 仮パスワード再送信
      MessageAction: "RESEND",
    });
    const res = await cognitoClient.send(command);
    return { res: res };
  } catch (err) {
    logger.error("Error AdminCreateUserCommand with: ", err);
    return {
      res: false,
      error: err as Cognito.InternalErrorException,
    };
  }
};

/**
 * 定刻に利用開始日のユーザーに対し、仮パスワードを記載したメールを送信するハンドラ
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
  await Promise.allSettled(
    userList.map(async (user) => {
      const usageStartDate = user.Attributes?.find(
        (attr) => attr.Name === "custom:usage_start_date"
      )?.Value;
      if (!usageStartDate) {
        logger.info(`Usage start date not found for user: ${user.Username}`);
        return;
      }

      /** 本日(ミリ秒換算) */
      const todayDateMS = new Date(todayDate).getTime();
      /** 利用開始日(ミリ秒換算) */
      const usageStartDateMS = new Date(usageStartDate).getTime();
      // 利用開始日になったら仮パスワードメールを送信
      if (todayDateMS === usageStartDateMS) {
        const email = user.Attributes?.find(
          (attr) => attr.Name === "email"
        )?.Value;
        if (!email) {
          logger.error(`Email not found for user: ${user.Username}`);
          return;
        }
        // 仮パスワードを記載したメールを送信
        await sendTemporaryPasswordEmail(secrets.cognitoUserPoolId, email);
        logger.info(`Sent temporary password email to ${email}`);
      }
    })
  );
};
