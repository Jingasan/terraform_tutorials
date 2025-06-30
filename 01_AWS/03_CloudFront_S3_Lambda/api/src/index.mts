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
const corsOptions = {
  origin: "*",
  methods: "GET, POST, PUT, DELETE",
  allowedHeaders:
    "Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token",
};
// CORS
app.use(cors(corsOptions));
// GET
app.get(
  "/api/sample/:id",
  (req: Request, res: Response, _next: NextFunction): Promise<void> => {
    res.status(200).json({ Query: req.query });
    return;
  }
);
// POST
app.post(
  "/api/sample/:id",
  (req: Request, res: Response, _next: NextFunction): Promise<void> => {
    const body = JSON.parse(req.body);
    res.status(200).json({ PostBody: body });
    return;
  }
);
// PUT
app.put(
  "/api/sample/:id",
  (req: Request, res: Response, _next: NextFunction): Promise<void> => {
    res.status(200).json({ RequestHeader: req.headers });
    return;
  }
);
// DELETE
app.delete(
  "/api/sample/:id",
  (req: Request, res: Response, _next: NextFunction): Promise<void> => {
    res.status(200).json({ URLParams: req.params.id });
    return;
  }
);
// Error 404 Not Found
app.use((_req: Request, res: Response, _next: NextFunction): Promise<void> => {
  res.status(404).json({
    error: "Lambda function is called.",
  });
  return;
});
// 関数エンドポイント
export const handler = serverlessExpress({
  app,
  binarySettings: {
    // バイナリコンテンツの判定
    isBinary: ({ headers }: { headers: Record<string, string> }) => {
      const contentType = headers["content-type"] || "";
      // trueを返した場合、Lambdaはレスポンスをバイナリコンテンツと判定し、Lambdaの仕様に則り、Base64エンコードして返す
      return !(
        contentType.startsWith("text/") ||
        contentType === "application/csv" ||
        contentType === "application/json" ||
        contentType === "application/javascript" ||
        contentType === "application/manifest+json" ||
        contentType === "application/rtf" ||
        contentType === "application/soap+xml" ||
        contentType === "application/sql" ||
        contentType === "application/x-javascript" ||
        contentType === "application/x-www-form-urlencoded" ||
        contentType === "application/xml" ||
        contentType === "application/xhtml+xml" ||
        contentType === "multipart/form-data"
      );
    },
  },
});
