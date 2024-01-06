import express from "express";
import cors from "cors";
const app = express();
const PORT = 80;
// リクエストボディのパース設定
// 1. JSON形式のリクエストボディをパースできるように設定
// 2. フォームの内容をパースできるように設定
// 3. Payload Too Large エラー対策：50MBまでのデータをPOSTできるように設定(default:100kb)
app.use(express.json({ limit: "50mb" }));
app.use(express.urlencoded({ limit: "50mb", extended: true }));

// CORS
const corsOptions = {
  origin: "*",
  methods: "GET, POST, PUT, DELETE",
  allowedHeaders:
    "Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token",
};

// 静的ファイルを返す処理
app.use(express.static("public"));

// GET
app.get("/users/:id", cors(corsOptions), async (req, res) => {
  return res.status(200).json({ Query: req.query });
});

// POST
app.post("/users/:id", cors(corsOptions), async (req, res) => {
  return res.status(200).json({ PostBody: req.body });
});

// PUT
app.put("/users/:id", cors(corsOptions), async (req, res) => {
  return res.status(200).json({ RequestHeader: req.headers });
});

// DELETE
app.delete("/users/:id", cors(corsOptions), async (req, res) => {
  return res.status(200).json({ URLParams: req.params.id });
});

// Error 404 Not Found
app.use(cors(corsOptions), async (_req, res) => {
  return res.status(404).json({
    error: "Not Found",
  });
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
