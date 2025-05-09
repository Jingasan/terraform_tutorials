/**
 * 仮のWebAPI（LGWAN向けAPI Gatewayの初回デプロイに必要）
 */
import serverlessExpress from "@codegenie/serverless-express";
import express, { Application, Request, Response, NextFunction } from "express";
import cors from "cors";
import bodyParser from "body-parser";
import * as sourceMapSupport from "source-map-support";
sourceMapSupport.install();
const app: Application = express();
// リクエストボディのパース用設定
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));
// CORS
app.use(cors());

// テストAPI
app.get("/test", (req: Request, res: Response, _next: NextFunction): void => {
  console.log("web_api_b");
  res.json({
    req: { url: req.url },
    res: "OK web_api_b",
  });
});

// Error 404 Not Found
app.use((req: Request, res: Response, _next: NextFunction): void => {
  console.log("web_api_b");
  res.status(404).json({ res: "Not Found web api b", req: { url: req.url } });
});

// 関数のエンドポイント
export const handler = serverlessExpress({ app });
