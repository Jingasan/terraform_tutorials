import express from "express";
import cors from "cors";
import * as IORedis from "ioredis";
const app = express();
const PORT = 3000;
// リクエストボディのパース設定
// 1. JSON形式のリクエストボディをパースできるように設定
// 2. フォームの内容をパースできるように設定
// 3. Payload Too Large エラー対策：50MBまでのデータをPOSTできるように設定(default:100kb)
app.use(express.json({ limit: "50mb" }));
app.use(express.urlencoded({ limit: "50mb", extended: true }));
// CORS設定
app.use(cors());
// Redisとの接続処理
const redisClient = new IORedis.Redis({
  host: String(process.env.REDIS_HOST), // Redisホスト名
  port: Number(process.env.REDIS_PORT), // Redisポート番号
  username: "default", // needs Redis >= 6
  // password: String(process.env.REDIS_SERVER_PASSWORD), // Redisパスワード
  // db: 0, // DBインデックス: 0 (default)
});
// key-valueの追加
app.post("/:key", async (req, res) => {
  try {
    // URLパラメータとBodyからのkey-value値の取得
    const key = req.params.key;
    const body = req.body;
    if (!("value" in body)) return res.status(400).json("Bad Request");
    // key-valueの追加(期限は30秒)
    await redisClient.set(key, JSON.stringify(body.value), "EX", 30);
    // レスポンス
    return res.status(200).json("OK");
  } catch (err) {
    // レスポンス
    return res.status(500).json(err);
  }
});
// key-valueの取得
app.get("/:key", async (req, res) => {
  try {
    // 指定したkeyの値の取得
    const key = req.params.key;
    const value = await redisClient.get(key);
    // レスポンス
    let json: any = {};
    json[key] = JSON.parse(value);
    return res.status(200).json(json);
  } catch (err) {
    // レスポンス
    return res.status(500).json(err);
  }
});
// key-valueの削除
app.delete("/:key", async (req, res) => {
  try {
    // 指定したkey-valueの削除
    const key = req.params.key;
    await redisClient.del(key);
    // レスポンス
    return res.status(200).json("OK");
  } catch (err) {
    // レスポンス
    return res.status(500).json(err);
  }
});
// GET
app.get("/", async (_req, res) => {
  console.info("API is called.");
  return res.status(200).json({
    message: `API is called. Host: ${String(
      process.env.REDIS_HOST
    )}, Port: ${Number(process.env.REDIS_PORT)}`,
  });
});
// Error 404 Not Found
app.use((_req, res) => {
  return res.status(404).json({ error: "Not Found" });
});
// サーバーを起動する処理
try {
  app.listen(PORT, () => {
    console.log("server running at port:" + PORT);
  });
} catch (e) {
  if (e instanceof Error) {
    console.error(e.message);
  }
}
