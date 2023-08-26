import serverlessExpress from "@vendia/serverless-express";
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
// GET
app.get(
  "/users/:id",
  cors(corsOptions),
  (req: Request, res: Response, _next: NextFunction) => {
    return res.status(200).json({ Query: req.query });
  }
);
// POST
app.post(
  "/users/:id",
  cors(corsOptions),
  (req: Request, res: Response, _next: NextFunction) => {
    const body = JSON.parse(req.body);
    return res.status(200).json({ PostBody: body });
  }
);
// PUT
app.put(
  "/users/:id",
  cors(corsOptions),
  (req: Request, res: Response, _next: NextFunction) => {
    return res.status(200).json({ RequestHeader: req.headers });
  }
);
// DELETE
app.delete(
  "/users/:id",
  cors(corsOptions),
  (req: Request, res: Response, _next: NextFunction) => {
    return res.status(200).json({ URLParams: req.params.id });
  }
);
// Error 404 Not Found
app.use(
  cors(corsOptions),
  (_req: Request, res: Response, _next: NextFunction) => {
    return res.status(404).json({
      error: "Not Found",
    });
  }
);
export const handler = serverlessExpress({ app });
