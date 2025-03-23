/**
 * ログイン時にワンタイムパスワードを送信するLambda
 */
import { SESv2Client, SendEmailCommand } from "@aws-sdk/client-sesv2";
import { CreateAuthChallengeTriggerEvent } from "aws-lambda";
import { Logger } from "@aws-lambda-powertools/logger";
const REGION = process.env.REGION || "ap-northeast-1";
const FROM_EMAIL_ADDRESS = process.env.SES_EMAIL_FROM || undefined;
const SERVICE_NAME = `[${process.env.SERVICE_NAME}] ` || "";
const logger = new Logger();
const sesClient = new SESv2Client({ region: REGION });

/**
 * ワンタイムパスワード(OTP)の送信ハンドラ
 * @param event イベント
 * @returns イベント
 */
export const handler = async (event: CreateAuthChallengeTriggerEvent) => {
  logger.info("CreateAuthChallenge event:", JSON.stringify(event, null, 2));
  // カスタムチャレンジの場合
  const challengeName = event.request.challengeName;
  if (challengeName === "CUSTOM_CHALLENGE") {
    // ユーザー名、メールアドレスを取得
    const { userName, request } = event;
    const email = request.userAttributes.email;
    if (!FROM_EMAIL_ADDRESS) {
      logger.error("FROM_EMAIL_ADDRESS is not set");
      return event;
    }
    if (!email) {
      logger.error("Email not found for user: ", userName);
      return event;
    }

    // OTPの生成(6桁の数字)
    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    // OTPをCognitoのセッションに保存
    event.response.publicChallengeParameters = {
      email: event.request.userAttributes.email,
    };
    event.response.privateChallengeParameters = { answer: otp };
    event.response.challengeMetadata = "CUSTOM_CHALLENGE";

    // メール内容
    const mailSub = `${SERVICE_NAME} ワンタイムパスワード`;
    const mailBody = `${email} 様<br/><br/>
いつもご利用いただき、ありがとうございます。<br/>
ワンタイムパスワードは「${otp}」です。`;
    // メール送信
    await sesClient.send(
      new SendEmailCommand({
        FromEmailAddress: FROM_EMAIL_ADDRESS,
        Destination: { ToAddresses: [email] },
        Content: {
          Simple: {
            Subject: { Data: mailSub },
            Body: { Html: { Data: mailBody } },
          },
        },
      })
    );
  }
  return event;
};
