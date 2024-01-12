import express from "express";
import cors from "cors";
import { GCSClient } from "./gcs.mjs";
const gcsClient = new GCSClient();
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
// GET
app.get("/", async (_req, res) => {
  const list = await gcsClient.listBuckets();
  console.log("List:");
  console.log(list);
  return res.status(200).json(list);
});
// Error 404 Not Found
app.use((_req, res) => {
  console.log(JSON.parse(process.env.CREDENTIALS));
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
