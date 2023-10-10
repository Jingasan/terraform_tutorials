import * as SES from "@aws-sdk/client-sesv2";
const sesClient = new SES.SESv2Client();

// メールの送信
const sendEmailCommand = async (
  mailContent: SES.SendEmailCommandInput
): Promise<boolean> => {
  try {
    // メール送信
    const res = await sesClient.send(new SES.SendEmailCommand(mailContent));
    console.log(res);
    return true;
  } catch (err) {
    console.error(err);
    return false;
  }
};

// メールの作成と送信
const runAll = async (): Promise<void> => {
  // メールコンテンツ
  const mailContent: SES.SendEmailCommandInput = {
    FromEmailAddress: "notify@route53-domain.com",
    Destination: {
      ToAddresses: ["xxx@gmail.com"],
      CcAddresses: [],
      BccAddresses: [],
    },
    Content: {
      Simple: {
        Subject: {
          Data: "Test email",
        },
        Body: {
          Text: {
            Data: "This is test email.",
          },
        },
      },
    },
  };
  // メール送信
  console.log("SendEmailCommand:");
  await sendEmailCommand(mailContent);
};
runAll();
