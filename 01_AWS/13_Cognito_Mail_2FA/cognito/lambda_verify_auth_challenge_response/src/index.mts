/**
 * ログイン時に二段階認証の認証チェックを行うLambda
 */
import { VerifyAuthChallengeResponseTriggerEvent } from "aws-lambda";
import { Logger } from "@aws-lambda-powertools/logger";
const logger = new Logger();

/**
 * VerifyAuthChallengeResponseトリガーのハンドラ
 * @param event イベント
 * @returns イベント
 */
export const handler = async (
  event: VerifyAuthChallengeResponseTriggerEvent
) => {
  logger.info(
    "VerifyAuthChallengeResponse event:",
    JSON.stringify(event, null, 2)
  );
  event.response.answerCorrect =
    event.request.privateChallengeParameters.answer ===
    event.request.challengeAnswer;
  return event;
};
