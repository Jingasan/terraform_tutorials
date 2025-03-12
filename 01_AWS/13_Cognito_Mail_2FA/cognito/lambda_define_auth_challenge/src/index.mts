import { DefineAuthChallengeTriggerEvent } from "aws-lambda";

/**
 * DefineAuthChallengeトリガーのハンドラ
 * @param event イベント
 * @returns イベント
 */
export const handler = async (event: DefineAuthChallengeTriggerEvent) => {
  console.log("DefineAuthChallenge event:", JSON.stringify(event, null, 2));
  console.log(JSON.stringify(event), null, 2);
  if (event.request.session.length === 0) {
    event.response.challengeName = "CUSTOM_CHALLENGE";
    console.log("CUSTOM_CHALLENGE1");
  } else if (
    event.request.session.find(
      (challenge) =>
        challenge.challengeName === "CUSTOM_CHALLENGE" &&
        challenge.challengeResult
    )
  ) {
    event.response.issueTokens = true;
    event.response.failAuthentication = false;
    console.log("CUSTOM_CHALLENGE2");
  } else {
    event.response.issueTokens = false;
    event.response.failAuthentication = true;
    console.log("failAuthentication");
  }
  console.log(JSON.stringify(event), null, 2);
  return event;
};
