/**
 * Cognitoのユーザー情報一覧をS3バケットに一時バックアップする定期実行Lambda
 */
import { parseISO, format } from "date-fns";
import { TZDate } from "@date-fns/tz";
import { ScheduledHandler, ScheduledEvent } from "aws-lambda";
import * as S3 from "@aws-sdk/client-s3";
import * as SecretsManager from "@aws-sdk/client-secrets-manager";
import * as Cognito from "@aws-sdk/client-cognito-identity-provider";
import { Logger } from "@aws-lambda-powertools/logger";
const REGION = process.env.REGION || "ap-northeast-1";
const SECRET_NAME = process.env.SECRET_NAME;
const SERVICE_NAME = process.env.SERVICE_NAME;
const logger = new Logger({ serviceName: SERVICE_NAME });
const s3client = new S3.S3Client({ region: REGION });
const cognitoClient = new Cognito.CognitoIdentityProviderClient({
  region: REGION,
});
const secretsManagerClient = new SecretsManager.SecretsManagerClient({
  region: REGION,
});

/**
 * SecretsManagerからシークレットおよび設定値を取得する
 * @returns シークレットおよび設定値
 */
const getSecrets = async (): Promise<
  | {
      cognitoUserPoolId: string;
      cognitoBackupBucketName: string;
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
      secret.cognitoBackupBucketName === undefined
    ) {
      logger.error("cognitoUserPoolId or cognitoBackupBucketName is not found");
      return undefined;
    }
    return {
      cognitoUserPoolId: secret.cognitoUserPoolId,
      cognitoBackupBucketName: secret.cognitoBackupBucketName,
    };
  } catch (error) {
    logger.error("SecretString is not JSON format");
    return undefined;
  }
};

/**
 * S3にオブジェクトを保存する
 * @param bucket バケット名
 * @param key 保存先のキー
 * @param obj 保存するオブジェクト
 * @param contentType ContentType
 * @returns true:成功/false:失敗
 */
const putObject = async (
  bucket: string,
  key: string,
  obj: string,
  contentType?: string
): Promise<boolean> => {
  try {
    const putObjectParam: S3.PutObjectCommandInput = {
      Bucket: bucket,
      Key: key,
      Body: obj,
      ContentType: contentType ? contentType : "application/octet-stream",
    };
    await s3client.send(new S3.PutObjectCommand(putObjectParam));
    return true;
  } catch (err) {
    logger.error(err, `Failed to put object s3://${bucket}/${key}`);
    return false;
  }
};

/**
 * ユーザー情報一覧CSVデータの作成
 * @param userList ユーザー情報一覧
 * @returns ユーザー情報一覧CSVデータ
 */
const createUserListCSV = (userList: Cognito.UserType[]): string => {
  const csvRows: string[] = [];
  // CSVヘッダー行の作成
  const csvHeaderRow: string[] = [];
  csvHeaderRow.push("email"); // メールアドレス
  csvHeaderRow.push("password_set_date"); // パスワード設定日
  csvHeaderRow.push("usage_start_date"); // 利用開始日
  csvHeaderRow.push("usage_end_date"); // 利用終了日
  csvHeaderRow.push("user_status"); // ユーザーステータス
  csvHeaderRow.push("enabled"); // 有効/無効
  csvRows.push(csvHeaderRow.join(","));
  // CSV行の作成
  for (const user of userList) {
    const csvRow: string[] = [];
    const email = user.Attributes?.find((attr) => attr.Name === "email")?.Value;
    csvRow.push(email ?? "");
    const passwordSetDate = user.Attributes?.find(
      (attr) => attr.Name === "custom:password_set_date"
    )?.Value;
    csvRow.push(
      passwordSetDate
        ? format(
            new TZDate(parseISO(passwordSetDate), "Asia/Tokyo"),
            "yyyy/MM/dd"
          )
        : ""
    );
    const usageStartDate = user.Attributes?.find(
      (attr) => attr.Name === "custom:usage_start_date"
    )?.Value;
    csvRow.push(
      usageStartDate
        ? format(
            new TZDate(parseISO(usageStartDate), "Asia/Tokyo"),
            "yyyy/MM/dd"
          )
        : ""
    );
    const usageEndDate = user.Attributes?.find(
      (attr) => attr.Name === "custom:usage_end_date"
    )?.Value;
    csvRow.push(
      usageEndDate
        ? format(new TZDate(parseISO(usageEndDate), "Asia/Tokyo"), "yyyy/MM/dd")
        : ""
    );
    csvRow.push(String(user.UserStatus ?? ""));
    csvRow.push(user.Enabled !== undefined ? String(user.Enabled) : "");
    csvRows.push(csvRow.join(","));
  }
  return csvRows.join("\n");
};

/**
 * ユーザー情報一覧の保存
 * @param bucket 保存先バケット名
 * @param userList ユーザー情報一覧
 * @returns true:成功/false:失敗
 */
const putUsersData = async (
  bucket: string,
  userList: Cognito.UserType[]
): Promise<boolean> => {
  // ユーザー情報一覧CSVの作成
  const csvString = createUserListCSV(userList);
  // S3バケットにCSVを保存
  return await putObject(bucket, "cognito_users.csv", csvString, "text/csv");
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
  if (!userList.length) {
    logger.info("No cognito user data");
    return;
  }

  // ユーザー情報一覧をS3バケットに保存
  const res = await putUsersData(secrets.cognitoBackupBucketName, userList);
  if (res) {
    logger.info("Succeeded to backup cognito users");
  } else {
    logger.info("Failed to backup cognito users");
  }
};
