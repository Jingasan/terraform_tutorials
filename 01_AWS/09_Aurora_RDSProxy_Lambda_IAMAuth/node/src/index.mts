import serverlessExpress from "@codegenie/serverless-express";
import express, { Application, Request, Response, NextFunction } from "express";
import cors from "cors";
import bodyParser from "body-parser";
import * as sourceMapSupport from "source-map-support";
import * as RDSSigner from "@aws-sdk/rds-signer";
import PG from "pg";
sourceMapSupport.install();
const app: Application = express();
// リクエストボディのパース用設定
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));
// CORS
app.use(cors());

// RDS関連の情報
const rdsProxyHostname = String(process.env.RDS_PROXY_HOSTNAME); // RDS Proxyのホスト名
const rdsPort = Number(process.env.RDS_PORT); // RDSポート番号
const rdsDatabase = String(process.env.RDS_DATABASE); // RDSデータベース名
const rdsUsername = String(process.env.RDS_USERNAME); // RDSマスターユーザー名
const rdsRegion = String(process.env.RDS_REGION); // RDSとRDS Proxyを配置したRegion

// RDS Proxy接続のためのトークンの取得
const getRDSProxyToken = async (): Promise<string | false> => {
  const rdsSigner = new RDSSigner.Signer({
    hostname: rdsProxyHostname, // RDS Proxyのホスト名
    port: rdsPort, // RDSのポート番号
    username: rdsUsername, // RDSのマスターユーザー名
    region: rdsRegion, // RDS Proxyを配置したRegion
  });
  try {
    console.log("> RDS Proxy 接続のためのトークンの取得");
    const token = await rdsSigner.getAuthToken();
    console.log("token: " + token);
    return token;
  } catch (err) {
    console.error(err);
    return false;
  }
};

// RDS Proxyとの接続初期化
const initRDSProxyConnection = async (): Promise<PG.Client | false> => {
  // RDS Proxy接続のためのトークンの取得
  const token = await getRDSProxyToken();
  if (!token) return false;
  try {
    console.log("> RDS Proxy 接続");
    const pg = new PG.Client({
      host: rdsProxyHostname, // RDS Proxyホスト名
      port: rdsPort, // RDSポート番号
      database: rdsDatabase, // RDSデータベース名
      user: rdsUsername, // RDSマスターユーザー名
      password: token, // RDS Proxy接続トークン
      ssl: true, // 暗号化通信を有効化
    });
    // RDS Proxyとの接続
    await pg.connect();
    return pg;
  } catch (err) {
    console.error(err);
    return false;
  }
};

// GET
app.get(
  "/",
  async (_req: Request, res: Response, _next: NextFunction): Promise<void> => {
    // RDS関連の情報表示
    console.log(`RDS Proxy Hostname: ${rdsProxyHostname}`);
    console.log(`RDS Port: ${rdsPort}`);
    console.log(`RDS Database: ${rdsDatabase}`);
    console.log(`RDS Username: ${rdsUsername}`);
    console.log(`RDS Region: ${rdsRegion}`);
    // RDS Proxyとの接続初期化
    const pg = await initRDSProxyConnection();
    if (!pg) {
      res.status(503).json("Internal Server Error");
      return;
    }
    // SQLの実行
    const sql = `show all`;
    console.log("> SQL 実行：" + sql);
    const result = await pg.query(sql);
    res.status(200).json(result);
    return;
  }
);

// 関数のエンドポイント
export const handler = serverlessExpress({ app });
