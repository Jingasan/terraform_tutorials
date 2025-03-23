/**
 * ユーザーに対し、ログイン通知を送信するLambda
 */
import { SESv2Client, SendEmailCommand } from "@aws-sdk/client-sesv2";
import { PostAuthenticationTriggerEvent } from "aws-lambda";
import { Logger } from "@aws-lambda-powertools/logger";
const REGION = process.env.REGION || "ap-northeast-1";
const FROM_EMAIL_ADDRESS = process.env.SES_EMAIL_FROM || undefined;
const SERVICE_NAME = `[${process.env.SERVICE_NAME}] ` || "";
const logger = new Logger();
const ses = new SESv2Client({ region: REGION });

/**
 * ログイン通知メールの送信ハンドラ
 * @param event イベント
 * @returns イベント
 */
export const handler = async (
  event: PostAuthenticationTriggerEvent
): Promise<PostAuthenticationTriggerEvent> => {
  logger.info("Event: ", JSON.stringify(event, null, 2));

  // ユーザー名、メールアドレスを取得
  const { userName, request } = event;
  const email = request.userAttributes.email;
  if (!FROM_EMAIL_ADDRESS) {
    logger.error("FROM_EMAIL_ADDRESS is not set");
    return event;
  }
  if (!email) {
    logger.error("Email not found for user:", userName);
    return event;
  }

  // メール内容
  const mailSub = `${SERVICE_NAME}ログイン通知`;
  const mailBody = `${email} 様<br/><br/>サービスへのログインがありました。`;

  // ログイン通知メール作成
  const params = new SendEmailCommand({
    FromEmailAddress: FROM_EMAIL_ADDRESS,
    Destination: { ToAddresses: [email] },
    Content: {
      Simple: {
        Subject: { Data: mailSub },
        Body: { Html: { Data: mailBody } },
      },
    },
  });

  // ログイン通知メールを送信
  try {
    await ses.send(params);
    logger.info("メール送信成功");
  } catch (error) {
    logger.error("メール送信失敗", error);
  }
  return event;
};
