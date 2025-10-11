import * as SecretsManager from "@aws-sdk/client-secrets-manager";
const SECRET_NAME = String(process.env.SECRET_NAME);

/**
 * メイン関数
 */
const main = async (): Promise<void> => {
  console.log("test job is started.");
  console.log(process.env);
  console.log("SECRET_NAME: " + SECRET_NAME);
  const client = new SecretsManager.SecretsManagerClient();
  try {
    const command = new SecretsManager.GetSecretValueCommand({
      SecretId: SECRET_NAME,
    });
    const res = await client.send(command);
    console.log("SecretString: ");
    console.log(res.SecretString);
  } catch (e) {
    throw new Error(e);
  }
  console.log("test job is finished.");
};
await main();
