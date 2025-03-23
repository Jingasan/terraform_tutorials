/**
 * ログイン時に二段階認証の認証チェックを行うLambda
 */
import { VerifyAuthChallengeResponseTriggerEvent } from "aws-lambda";

/**
 * VerifyAuthChallengeResponseトリガーのハンドラ
 * @param event イベント
 * @returns イベント
 */
export const handler = async (
  event: VerifyAuthChallengeResponseTriggerEvent
) => {
  console.log(
    "VerifyAuthChallengeResponse event:",
    JSON.stringify(event, null, 2)
  );
  event.response.answerCorrect =
    event.request.privateChallengeParameters.answer ===
    event.request.challengeAnswer;
  return event;
};
