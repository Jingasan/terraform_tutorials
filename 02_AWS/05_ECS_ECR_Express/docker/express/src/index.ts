import express, { Application, Request, Response, NextFunction } from "express";
import cors from "cors";
const app: Application = express();
const PORT = 80;

// リクエストボディのパース用設定
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

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
app.get(
  "/users/:id",
  cors(corsOptions),
  async (req: Request, res: Response, _next: NextFunction) => {
    return res.status(200).json({ Query: req.query });
  }
);

// POST
app.post(
  "/users/:id",
  cors(corsOptions),
  async (req: Request, res: Response, _next: NextFunction) => {
    return res.status(200).json({ PostBody: req.body });
  }
);

// PUT
app.put(
  "/users/:id",
  cors(corsOptions),
  async (req: Request, res: Response, _next: NextFunction) => {
    return res.status(200).json({ RequestHeader: req.headers });
  }
);

// DELETE
app.delete(
  "/users/:id",
  cors(corsOptions),
  async (req: Request, res: Response, _next: NextFunction) => {
    return res.status(200).json({ URLParams: req.params.id });
  }
);

// Error 404 Not Found
app.use(
  cors(corsOptions),
  async (_req: Request, res: Response, _next: NextFunction) => {
    return res.status(404).json({
      error: "Not Found",
    });
  }
);

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
