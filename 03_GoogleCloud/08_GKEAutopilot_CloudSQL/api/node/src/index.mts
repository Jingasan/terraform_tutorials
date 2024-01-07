import express from "express";
import cors from "cors";
import PG from "pg";
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
  return res.status(200).send({
    message: "Hello World!",
  });
});
// GET
app.get("/rds", async (_req, res) => {
  console.log(`HOST: ${String(process.env.RDS_HOST)}`);
  console.log(`PORT: ${String(process.env.RDS_PORT)}`);
  console.log(`DATABASE: ${String(process.env.RDS_DATABASE)}`);
  console.log(`USERNAME: ${String(process.env.RDS_USERNAME)}`);
  console.log(`PASSWORD: ${String(process.env.RDS_PASSWORD)}`);
  const pg = new PG.Client({
    host: String(process.env.RDS_HOST), // RDSホスト名
    port: Number(process.env.RDS_PORT), // RDSポート番号
    database: String(process.env.RDS_DATABASE), // RDSデータベース名
    user: String(process.env.RDS_USERNAME), // RDSユーザー名
    password: String(process.env.RDS_PASSWORD), // RDSユーザーパスワード
  });
  // RDSとの接続
  await pg.connect();
  if (!pg) return res.status(503).json("RDS Connection Error");
  // SQLの実行
  const sql = `show all`;
  console.log("> Run SQL: " + sql);
  const result = await pg.query(sql);
  return res.status(200).json(result);
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
