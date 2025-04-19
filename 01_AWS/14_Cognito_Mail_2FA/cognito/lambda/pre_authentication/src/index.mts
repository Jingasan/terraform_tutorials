/**
 * ログイン直前にパスワード有効期限切れ、利用開始日、利用終了日をチェックするLambda
 */
import * as sourceMapSupport from "source-map-support";
import { format } from "date-fns";
import { TZDate } from "@date-fns/tz";
import { PreAuthenticationTriggerEvent } from "aws-lambda";
import * as SecretsManager from "@aws-sdk/client-secrets-manager";
import { Logger } from "@aws-lambda-powertools/logger";
sourceMapSupport.install();
const REGION = process.env.REGION || "ap-northeast-1";
const SECRET_NAME = process.env.SECRET_NAME;
const SERVICE_NAME = process.env.SERVICE_NAME;
const logger = new Logger({ serviceName: SERVICE_NAME });
const secretsManagerClient = new SecretsManager.SecretsManagerClient({
  region: REGION,
});
/** デフォルトのパスワード有効期間(日) */
const DEFAULT_EXPIRATION_DAYS = 90;

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
 * パスワード有効期間(日)をSecretsManagerから取得(取得できない場合はデフォルト値を返す)
 * @returns パスワード有効期間(日)
 */
const getPasswordExpirationDays = async (): Promise<number> => {
  if (!SECRET_NAME) {
    logger.error("SECRET_NAME is not set");
    return DEFAULT_EXPIRATION_DAYS;
  }
  const command = new SecretsManager.GetSecretValueCommand({
    SecretId: SECRET_NAME,
  });
  const res = await secretsManagerClient.send(command);
  if (!res.SecretString) {
    logger.error("SecretString is not found");
    return DEFAULT_EXPIRATION_DAYS;
  }
  try {
    const secret = JSON.parse(res.SecretString);
    if (secret.passwordExpirationDays === undefined) {
      console.warn("passwordExpirationDays is not found");
      return DEFAULT_EXPIRATION_DAYS;
    }
    return secret.passwordExpirationDays as number;
  } catch (error) {
    logger.error("SecretString is not JSON format");
    return DEFAULT_EXPIRATION_DAYS;
  }
};

/**
 * パスワードが有効かどうかチェック
 * @param currentLoginDate 現在ログイン日(日本時刻yyyy/MM/dd)
 * @param passwordSetDate パスワード設定日(日本時刻yyyy/MM/dd)
 * @returns true: 有効期限内, false: 有効期限切れ
 */
const checkPasswordNotExpired = async (
  currentLoginDate: string,
  passwordSetDate?: string
): Promise<boolean> => {
  try {
    logger.info(`Password set date: ${passwordSetDate}`);
    if (!passwordSetDate) return true;
    // パスワード有効期間を取得
    const passwordExpirationDays = await getPasswordExpirationDays();
    logger.info(`Password expiration days: ${passwordExpirationDays}`);
    // パスワード設定日(ミリ秒換算)を取得
    const passwordSetDateMS = new Date(passwordSetDate).getTime();
    logger.info(`Password set date [ms]: ${passwordSetDateMS}`);
    // パスワード有効期限日(ミリ秒換算)を計算
    const expiryDateMS =
      passwordSetDateMS + passwordExpirationDays * 24 * 60 * 60 * 1000;
    logger.info(`Expiry date [ms]: ${expiryDateMS}`);
    // 現在ログイン日(ミリ秒換算)を取得
    const currentLoginDateMS = new Date(currentLoginDate).getTime();
    logger.info(`Current login date [ms]: ${currentLoginDateMS}`);
    // true: 有効期限内, false: 有効期限切れ
    return currentLoginDateMS <= expiryDateMS;
  } catch (error) {
    logger.error("checkPasswordNotExpired Exception:", error);
    return false;
  }
};

/**
 * 利用開始日に至っているかどうかチェック
 * @param currentLoginDate 現在ログイン日(日本時刻yyyy/MM/dd)
 * @param usageStartDate 利用開始日(日本時刻yyyy/MM/dd)
 * @returns true: 利用開始日に至っている, false: 利用開始日に至っていない
 */
const checkAfterUsageStartDate = (
  currentLoginDate: string,
  usageStartDate?: string
) => {
  try {
    logger.info(`Usage start date: ${usageStartDate}`);
    if (!usageStartDate) return true;
    // 利用開始日(ミリ秒換算)を取得
    const usageStartDateMS = new Date(usageStartDate).getTime();
    logger.info(`Usage start date [ms]: ${usageStartDateMS}`);
    // 現在ログイン日(ミリ秒換算)を取得
    const currentLoginDateMS = new Date(currentLoginDate).getTime();
    logger.info(`Current login date [ms]: ${currentLoginDateMS}`);
    return usageStartDateMS <= currentLoginDateMS;
  } catch (error) {
    logger.error("checkAfterUsageStartDate Exception:", error);
    return false;
  }
};

/**
 * 利用終了日を過ぎていないかどうかチェック
 * @param currentLoginDate 現在ログイン日(日本時刻yyyy/MM/dd)
 * @param usageEndDate 利用終了日(日本時刻yyyy/MM/dd)
 * @returns true: 利用終了日を過ぎていない, false: 利用終了日を過ぎている
 */
const checkBeforeUsageEndDate = (
  currentLoginDate: string,
  usageEndDate: string
) => {
  try {
    logger.info(`Usage end date: ${usageEndDate}`);
    if (!usageEndDate) return true;
    // 利用終了日(ミリ秒換算)を取得
    const usageEndDateMS = new Date(usageEndDate).getTime();
    logger.info(`Usage end date [ms]: ${usageEndDateMS}`);
    // 現在ログイン日(ミリ秒換算)を取得
    const currentLoginDateMS = new Date(currentLoginDate).getTime();
    logger.info(`Current login date [ms]: ${currentLoginDateMS}`);
    return currentLoginDateMS <= usageEndDateMS;
  } catch (error) {
    logger.error("checkBeforeUsageEndDate Exception:", error);
    return false;
  }
};

/**
 * PreAuthenticationトリガーのハンドラ
 * @param event イベント
 * @returns イベント
 */
export const handler = async (event: PreAuthenticationTriggerEvent) => {
  logger.info(`PreAuthentication event: ${JSON.stringify(event, null, 2)}`);

  // ユーザーが存在しない場合：認証エラー
  if (event.request.userNotFound) {
    logger.info("User not found");
    throw new Error("USER_NOT_FOUND");
  }

  // ユーザー属性を取得
  const userAttributes = event.request.userAttributes;
  const passwordSetDate = userAttributes["custom:password_set_date"];
  const usageStartDate = userAttributes["custom:usage_start_date"];
  const usageEndDate = userAttributes["custom:usage_end_date"];

  // パスワード有効期限日、利用開始日、利用終了日が存在しない場合は認証を許可
  if (!passwordSetDate && !usageStartDate && !usageEndDate) {
    logger.info(
      "NO_PASSWORD_SET_DATE & NO_USAGE_START_DATE & NO_USAGE_END_DATE"
    );
    return event;
  }

  // ログイン日(日本時刻)を取得
  const currentLoginDate = getJSTDate(new Date());
  logger.info(`Current login date: ${currentLoginDate}`);

  // パスワードが有効期限切れの場合：認証エラー
  if (!(await checkPasswordNotExpired(currentLoginDate, passwordSetDate))) {
    logger.info("Your password has expired. Please reset your password.");
    throw new Error("PASSWORD_HAS_EXPIRED");
  }

  // 利用開始日に至ってない場合：認証エラー
  if (!checkAfterUsageStartDate(currentLoginDate, usageStartDate)) {
    logger.info("Your usage period has not started yet.");
    throw new Error("USAGE_PERIOD_HAS_NOT_STARTED");
  }

  // 利用終了日を過ぎている場合：認証エラー
  if (!checkBeforeUsageEndDate(currentLoginDate, usageEndDate)) {
    logger.info("Your usage period has passed.");
    throw new Error("USAGE_PERIOD_HAS_PASSED");
  }

  // パスワードが有効期間内、利用期間内の場合
  logger.info("Password and usage period is valid.");
  return event;
};
