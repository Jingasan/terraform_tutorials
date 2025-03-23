/**
 * ログイン時に二段階認証を管理するLambda
 */
import { DefineAuthChallengeTriggerEvent } from "aws-lambda";

/**
 * DefineAuthChallengeトリガーのハンドラ
 * @param event イベント
 * @returns イベント
 */
export const handler = async (event: DefineAuthChallengeTriggerEvent) => {
  console.log(
    "DefineAuthChallenge event request:",
    JSON.stringify(event, null, 2)
  );
  if (event.request.session.length === 0) {
    // 初回アクセス時 → 二段階認証に移行
    event.response.challengeName = "CUSTOM_CHALLENGE";
    console.log("To challenge 2FA");
  } else if (
    event.request.session.find(
      (challenge) =>
        challenge.challengeName === "CUSTOM_CHALLENGE" &&
        challenge.challengeResult
    )
  ) {
    // 二段階認証成功時
    event.response.issueTokens = true;
    event.response.failAuthentication = false;
    console.log("Succeeded to challenge 2FA");
  } else {
    // 二段階認証失敗時
    event.response.issueTokens = false;
    event.response.failAuthentication = true;
    console.log("Failed to challenge 2FA");
  }
  console.log(
    "DefineAuthChallenge event response:",
    JSON.stringify(event, null, 2)
  );
  return event;
};
