import serverlessExpress, {
  getCurrentInvoke,
} from "@vendia/serverless-express";
import express, { Application, Request, Response, NextFunction } from "express";
import cors from "cors";
import bodyParser from "body-parser";
import * as sourceMapSupport from "source-map-support";
import intercept from "azure-function-log-intercept";
sourceMapSupport.install();
const app: Application = express();
// リクエストボディのパース用設定
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));
// CORS
app.use(cors());

// GET
app.get("/api/test", async (_req: Request, res: Response): Promise<void> => {
  res.status(200).json("ENV_NAME: " + process.env.ENV_NAME);
});

// GET
app.get(
  "/api/test/:workspace/:project",
  async (req: Request, res: Response): Promise<void> => {
    intercept(getCurrentInvoke().event);
    console.log("workspace: " + req.params.workspace);
    console.log("project: " + req.params.project);
    res.status(200).json({
      workspace: req.params.workspace,
      project: req.params.project,
    });
  }
);

// Error 404 Not Found
app.use((_req: Request, res: Response, _next: NextFunction): any => {
  return res.status(404).json("Azure Functions is called.");
});

// 関数のエンドポイント
const cachedServerlessExpress = serverlessExpress({ app });
module.exports = async function (event: any, context: any) {
  return cachedServerlessExpress(event, context, null);
};
