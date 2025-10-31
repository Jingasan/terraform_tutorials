import serverlessExpress from "@codegenie/serverless-express";
import express, { Application, Request, Response, NextFunction } from "express";
import cors from "cors";
import bodyParser from "body-parser";
import * as sourceMapSupport from "source-map-support";
import { PgClient } from "./pgClient.mjs";
import { KnexClient } from "./knexClient.mjs";
sourceMapSupport.install();
const app: Application = express();
// リクエストボディのパース用設定
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));
// CORS
app.use(cors());

// RDS関連の情報（※本番環境ではSecretsManagerから取得すべき）
const rdsProxyHostname = String(process.env.RDS_PROXY_HOSTNAME); // RDS Proxyのホスト名
const rdsPort = Number(process.env.RDS_PORT); // RDSポート番号
const rdsDatabase = String(process.env.RDS_DATABASE); // RDSデータベース名
const rdsUsername = String(process.env.RDS_USERNAME); // RDSマスターユーザー名
const rdsPassword = String(process.env.RDS_PASSWORD); // RDSマスターパスワード
const rdsRegion = String(process.env.RDS_REGION); // RDSとRDS Proxyを配置したRegion

/**
 * PGのシングルトンインスタンスの作成
 */
PgClient.initialize({
  host: rdsProxyHostname,
  port: rdsPort,
  database: rdsDatabase,
  username: rdsUsername,
  password: rdsPassword,
  region: rdsRegion,
  ssl: true,
});

/**
 * Knexのシングルトンインスタンスの生成
 */
KnexClient.initialize({
  host: rdsProxyHostname,
  port: rdsPort,
  database: rdsDatabase,
  username: rdsUsername,
  password: rdsPassword,
  region: rdsRegion,
  ssl: true,
});

// PG版
app.get(
  "/",
  async (_req: Request, res: Response, _next: NextFunction): Promise<void> => {
    try {
      // RDS関連の情報表示
      console.log(`RDS Proxy Hostname: ${rdsProxyHostname}`);
      console.log(`RDS Port: ${rdsPort}`);
      console.log(`RDS Database: ${rdsDatabase}`);
      console.log(`RDS Username: ${rdsUsername}`);
      console.log(`RDS Region: ${rdsRegion}`);
      // 接続プールの取得
      const pool = await PgClient.getPool();
      // SQLの実行
      const sql = `show all`;
      console.log("> SQL 実行：" + sql);
      const result = await pool.query(sql);
      res.status(200).json(result);
    } catch (err) {
      console.error(err);
      res.status(500).json({ error: "DB query failed." });
    }
  }
);

// Knex版
app.get(
  "/knex",
  async (_req: Request, res: Response, _next: NextFunction): Promise<void> => {
    try {
      // RDS関連の情報表示
      console.log(`RDS Proxy Hostname: ${rdsProxyHostname}`);
      console.log(`RDS Port: ${rdsPort}`);
      console.log(`RDS Database: ${rdsDatabase}`);
      console.log(`RDS Username: ${rdsUsername}`);
      console.log(`RDS Region: ${rdsRegion}`);
      // Knexのシングルトンインスタンスの取得
      const knex = await KnexClient.getInstance();
      // SQLの実行
      const sql = `show all`;
      console.log("> SQL 実行：" + sql);
      const result = await knex.raw(sql);
      res.status(200).json(result);
    } catch (err) {
      console.error(err);
      res.status(500).json({ error: "DB query failed." });
    }
  }
);

// 関数のエンドポイント
export const handler = serverlessExpress({ app });
