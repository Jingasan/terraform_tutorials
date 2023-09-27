import serverlessExpress, {
  getCurrentInvoke,
} from "@vendia/serverless-express";
import express, { Application, Request, Response, NextFunction } from "express";
import cors from "cors";
import bodyParser from "body-parser";
import * as sourceMapSupport from "source-map-support";
import intercept from "azure-function-log-intercept";
import * as PG from "pg";
sourceMapSupport.install();
const app: Application = express();
// リクエストボディのパース用設定
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));
// CORS
app.use(cors());

// DB関連の情報
const dbHostname = String(process.env.DB_HOSTNAME); // DBサーバーホスト名
const dbPort = Number(process.env.DB_PORT); // DBサーバーポート番号
const db = String(process.env.DB_DATABASE); // データベース名
const dbUsername = String(process.env.DB_USERNAME); // ユーザー名
const dbPassword = String(process.env.DB_PASSWORD); // パスワード

// DBとの接続初期化
const initRDSConnection = async (): Promise<PG.Client | false> => {
  try {
    console.log("> DB 接続");
    const pg = new PG.Client({
      host: dbHostname, // DBサーバーホスト名
      port: dbPort, // DBサーバーポート番号
      database: db, // データベース名
      user: dbUsername, // DBマスターユーザー名
      password: dbPassword, // DBパスワード
      ssl: true, // 暗号化通信を有効化
    });
    // DBとの接続
    await pg.connect();
    return pg;
  } catch (e) {
    console.error(e);
    return false;
  }
};

// GET
app.get("/api/rds", async (_req: Request, res: Response) => {
  intercept(getCurrentInvoke().event);
  console.log("DB_HOSTNAME: " + dbHostname);
  console.log("DB_PORT: " + dbPort);
  console.log("DB_NAME: " + db);
  console.log("DB_USERNAME: " + dbUsername);
  console.log("DB_PASSWORD: " + dbPassword);
  // DBとの接続初期化
  const pg = await initRDSConnection();
  if (!pg) {
    console.error("Failed to init RDS connection");
    return res.status(503).json("Internal Server Error");
  }
  // SQLの実行
  const sql = `show all`;
  console.log("> SQL 実行：" + sql);
  const result = await pg.query(sql);
  return res.status(200).json(result);
});

// Error 404 Not Found
app.use((_req: Request, res: Response, _next: NextFunction): any => {
  return res.status(404).json("Azure Functions is called.");
});

// 関数のエンドポイント
const cachedServerlessExpress = serverlessExpress({ app });
module.exports = async function (event: any, context: any) {
  return cachedServerlessExpress(event, context, null);
};
