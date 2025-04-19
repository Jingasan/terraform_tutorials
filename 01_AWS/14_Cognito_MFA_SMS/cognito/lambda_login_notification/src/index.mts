import { SESv2Client, SendEmailCommand } from "@aws-sdk/client-sesv2";
import { PostAuthenticationTriggerEvent } from "aws-lambda";
const ses = new SESv2Client({ region: "ap-northeast-1" });
const FROM_EMAIL_ADDRESS = process.env.SES_EMAIL_FROM || undefined;
const SERVICE_NAME = `${process.env.SERVICE_NAME} ` || "";

/**
 * ログイン通知メールの送信ハンドラ
 * @param event イベント
 * @returns イベント
 */
export const handler = async (
  event: PostAuthenticationTriggerEvent
): Promise<PostAuthenticationTriggerEvent> => {
  console.log("Event: ", JSON.stringify(event, null, 2));

  // ユーザー名、メールアドレスを取得
  const { userName, request } = event;
  const email = request.userAttributes.email;
  if (!FROM_EMAIL_ADDRESS) {
    console.error("FROM_EMAIL_ADDRESS is not set");
    return event;
  }
  if (!email) {
    console.error("Email not found for user:", userName);
    return event;
  }

  // ログインデバイス情報の取得
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
    console.log("メール送信成功");
  } catch (error) {
    console.error("メール送信失敗", error);
  }
  return event;
};
