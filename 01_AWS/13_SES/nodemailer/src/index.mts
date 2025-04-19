import * as SES from "@aws-sdk/client-ses";
import NodeMailer from "nodemailer";

// メールの作成と送信
const runAll = async (): Promise<void> => {
  const sesClient = new SES.SES();
  const transporter = NodeMailer.createTransport({
    SES: { ses: sesClient, aws: SES },
  });
  try {
    const res = await transporter.sendMail({
      from: "notify@route53-domain.com",
      to: ["xxx@gmail.com"],
      cc: [],
      bcc: [],
      subject: "Test email",
      text: "This is test email.",
    });
    console.log(res);
  } catch (e) {
    console.error(e);
  }
};
runAll();
