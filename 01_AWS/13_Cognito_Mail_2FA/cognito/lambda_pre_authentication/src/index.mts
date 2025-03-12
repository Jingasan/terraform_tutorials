import { PreAuthenticationTriggerEvent } from "aws-lambda";
import * as SecretsManager from "@aws-sdk/client-secrets-manager";
const REGION = process.env.REGION || "ap-northeast-1";
const SECRET_NAME = process.env.SECRET_NAME;
const secretsManagerClient = new SecretsManager.SecretsManagerClient({
  region: REGION,
});
/** デフォルトのパスワード有効期間(日) */
const DEFAULT_EXPIRATION_DAYS = 90;

/**
 * パスワード有効期間(日)をSecretsManagerから取得(取得できない場合はデフォルト値を返す)
 * @returns パスワード有効期間(日)
 */
const getPasswordExpirationDays = async (): Promise<number> => {
  if (!SECRET_NAME) {
    console.error("SECRET_NAME is not set");
    return DEFAULT_EXPIRATION_DAYS;
  }
  const command = new SecretsManager.GetSecretValueCommand({
    SecretId: SECRET_NAME,
  });
  const res = await secretsManagerClient.send(command);
  if (!res.SecretString) {
    console.error("SecretString is not found");
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
    console.error("SecretString is not JSON format");
    return DEFAULT_EXPIRATION_DAYS;
  }
};

/**
 * パスワードが有効かどうかチェック
 * @param currentLoginTime ログイン現在時刻
 * @param passwordSetDate パスワード設定日(ISO8601形式)
 * @returns true: 有効期限内, false: 有効期限切れ
 */
const checkPasswordNotExpired = async (
  currentLoginTime: number,
  passwordSetDate?: string
): Promise<boolean> => {
  try {
    console.log("Password set date:", passwordSetDate);
    if (!passwordSetDate) return true;
    // パスワード有効期間を取得
    const passwordExpirationDays = await getPasswordExpirationDays();
    console.log("Password expiration days:", passwordExpirationDays);
    // パスワード設定日(UTC秒)を取得
    const passwordSetTime = new Date(passwordSetDate).getTime();
    console.log("Password set time:", passwordSetTime);
    // パスワード有効期限日(UTC秒)を計算
    const expiryTime =
      passwordSetTime + passwordExpirationDays * 24 * 60 * 60 * 1000;
    console.log("Expiry time:", expiryTime);
    // true: 有効期限内, false: 有効期限切れ
    return currentLoginTime <= expiryTime;
  } catch (error) {
    console.error("checkPasswordNotExpired Exception:", error);
    return false;
  }
};

/**
 * 利用開始日に至っているかどうかチェック
 * @param currentLoginTime ログイン現在時刻
 * @param usageStartDate 利用開始日(ISO8601形式)
 * @returns true: 利用開始日に至っている, false: 利用開始日に至っていない
 */
const checkAfterUsageStartDate = (
  currentLoginTime: number,
  usageStartDate?: string
) => {
  try {
    console.log("Usage start date:", usageStartDate);
    if (!usageStartDate) return true;
    // 利用開始日(UTC秒)を取得
    const usageStartTime = new Date(usageStartDate).getTime();
    console.log("Usage start time:", usageStartTime);
    return usageStartTime <= currentLoginTime;
  } catch (error) {
    console.error("checkAfterUsageStartDate Exception:", error);
    return false;
  }
};

/**
 * 利用終了日を過ぎていないかどうかチェック
 * @param currentLoginTime ログイン現在時刻
 * @param usageEndDate 利用終了日(ISO8601形式)
 * @returns true: 利用終了日を過ぎていない, false: 利用終了日を過ぎている
 */
const checkBeforeUsageEndDate = (
  currentLoginTime: number,
  usageEndDate: string
) => {
  try {
    console.log("Usage end date:", usageEndDate);
    if (!usageEndDate) return true;
    // 利用終了日(UTC秒)を取得
    const usageEndTime = new Date(usageEndDate).getTime();
    console.log("Usage end time:", usageEndTime);
    return currentLoginTime <= usageEndTime;
  } catch (error) {
    console.error("checkBeforeUsageEndDate Exception:", error);
    return false;
  }
};

/**
 * PreAuthenticationトリガーのハンドラ
 * @param event イベント
 * @returns イベント
 */
export const handler = async (event: PreAuthenticationTriggerEvent) => {
  console.log("PreAuthentication event:", JSON.stringify(event, null, 2));

  // ユーザーが存在しない場合：認証エラー
  if (event.request.userNotFound) {
    console.log("User not found");
    throw new Error("USER_NOT_FOUND");
  }

  // ユーザー属性を取得
  const userAttributes = event.request.userAttributes;
  const passwordSetDate = userAttributes["custom:password_set_date"];
  const usageStartDate = userAttributes["custom:usage_start_date"];
  const usageEndDate = userAttributes["custom:usage_end_date"];

  // パスワード有効期限日、利用開始日、利用終了日が存在しない場合は認証を許可
  if (!passwordSetDate && !usageStartDate && !usageEndDate) {
    console.log(
      "NO_PASSWORD_SET_DATE & NO_USAGE_START_DATE & NO_USAGE_END_DATE"
    );
    return event;
  }

  // ログイン現在時刻(UTC秒)を取得
  const currentLoginTime = Date.now();
  console.log("Current login time:", currentLoginTime);

  // パスワードが有効期限切れの場合：認証エラー
  if (!(await checkPasswordNotExpired(currentLoginTime, passwordSetDate))) {
    console.log("Your password has expired. Please reset your password.");
    throw new Error("PASSWORD_HAS_EXPIRED");
  }

  // 利用開始日に至ってない場合：認証エラー
  if (!checkAfterUsageStartDate(currentLoginTime, usageStartDate)) {
    console.log("Your usage period has not started yet.");
    throw new Error("USAGE_PERIOD_HAS_NOT_STARTED");
  }

  // 利用終了日を過ぎている場合：認証エラー
  if (!checkBeforeUsageEndDate(currentLoginTime, usageEndDate)) {
    console.log("Your usage period has passed.");
    throw new Error("USAGE_PERIOD_HAS_PASSED");
  }

  // パスワードが有効期間内、利用期間内の場合
  console.log("Password and usage period is valid.");
  return event;
};
