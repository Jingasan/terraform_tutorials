import * as RDSSigner from "@aws-sdk/rds-signer";

/**
 * RDS接続のためのIAM認証トークン取得
 * @param dbConfig DBとの接続設定
 * @returns IAM認証トークン
 */
export const generateIAMAuthToken = async (dbConfig: {
  /** RDSのホスト名 */
  hostname: string;
  /** RDSのポート番号 */
  port: number;
  /** RDSのマスターユーザー名 */
  username: string;
  /** RDSを配置したリージョン */
  region: string;
}): Promise<string> => {
  const rdsSigner = new RDSSigner.Signer({
    hostname: dbConfig.hostname,
    port: dbConfig.port,
    username: dbConfig.username,
    region: dbConfig.region,
  });
  console.log("> RDS接続のためのIAM認証トークン取得");
  const token = await rdsSigner.getAuthToken();
  console.log("token: " + token);
  return token;
};
