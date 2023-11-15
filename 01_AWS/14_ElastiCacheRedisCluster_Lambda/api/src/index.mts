import serverlessExpress from "@vendia/serverless-express";
import express from "express";
import { Redis } from "ioredis";
import cors from "cors";
import bodyParser from "body-parser";
import * as sourceMapSupport from "source-map-support";
sourceMapSupport.install();
const app = express();
// リクエストボディのパース用設定
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));
// CORS
app.use(cors());
// Redisクラスター接続の初期化
const redisClient = new Redis.Cluster(
  [
    {
      host: String(process.env.REDIS_ENDPOINT),
      port: Number(process.env.REDIS_PORT),
    },
  ],
  // ElastiCache Redisにおける転送中の暗号化(TLS通信)の有効化
  {
    dnsLookup: (address, callback) => callback(null, address),
    redisOptions: { tls: {} },
  }
);
// POST
app.post("/", async (req, res) => {
  const body = req.body;
  const key = String(body.key);
  const value = String(body.value);
  // 1分の期限付きでキーと値を格納
  const result = await redisClient.set(key, value, "EX", 60);
  console.log({ key: key, value: value, result: result });
  return res.status(200).json(result);
});
// GET
app.get("/", async (req, res) => {
  const key = String(req.query.key);
  // キーの値を取得
  let value: string;
  try {
    value = await redisClient.get(key);
  } catch (e) {
    return res.status(500).json(e);
  }
  console.log({ key: key, value: value });
  return res.status(200).json({ key: key, value: value });
});
// Error 404 Not Found
app.use((_req, res) => {
  return res.status(404).json({
    error: "Lambda function is called.",
  });
});
// 関数エンドポイント
export const handler = serverlessExpress({ app });
