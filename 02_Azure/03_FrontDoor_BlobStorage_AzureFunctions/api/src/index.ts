import serverlessExpress, {
  getCurrentInvoke,
} from "@vendia/serverless-express";
import express, { Application, Request, Response, NextFunction } from "express";
import cors from "cors";
import bodyParser from "body-parser";
import * as sourceMapSupport from "source-map-support";
import intercept from "azure-function-log-intercept";
import { ManagedIdentityCredential } from "@azure/identity";
import { BlobServiceClient, ContainerClient } from "@azure/storage-blob";
sourceMapSupport.install();
const app: Application = express();
// リクエストボディのパース用設定
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));
// CORS
app.use(cors());

// GET
app.get("/api/blob", async (_req: Request, res: Response): Promise<void> => {
  const storageAccountName = String(process.env.STORAGE_ACCOUNT_NAME); // ストレージアカウント名
  const storageContainerName = String(process.env.STORAGE_CONTAINER_NAME); // ストレージコンテナ名
  intercept(getCurrentInvoke().event);
  console.log("StorageAccountName: " + storageAccountName);
  console.log("StorageContainerName: " + storageContainerName);
  // BlobServiceClientオブジェクトの取得
  let blobServiceClient: BlobServiceClient;
  try {
    blobServiceClient = new BlobServiceClient(
      `https://${storageAccountName}.blob.core.windows.net`,
      new ManagedIdentityCredential()
    );
  } catch (e) {
    console.error(e);
    res.status(503).json(e);
  }
  // ContainerClientオブジェクトの取得
  let containerClient: ContainerClient;
  try {
    containerClient =
      blobServiceClient.getContainerClient(storageContainerName);
  } catch (e) {
    console.error(e);
    res.status(503).json(e);
  }
  // コンテナが存在しない場合
  if (!(await containerClient.exists())) {
    res.status(200).json("No container exists.");
  }
  // 指定ディレクトリ内のBLOB一覧の取得
  const listPath = ""; // BLOB一覧を取得する際のトップディレクトリ
  let fileList: string[] = []; // BLOB一覧
  try {
    for await (const blob of containerClient.listBlobsFlat({
      prefix: listPath,
    })) {
      fileList.push(blob.name);
    }
  } catch (e) {
    console.error(e);
    res.status(503).json(e);
  }
  console.log(fileList);
  res.status(200).json(fileList);
});

// Error 404 Not Found
app.use((_req: Request, res: Response, _next: NextFunction): any => {
  return res.status(404).json("Azure Functions is called.");
});

// 関数のエンドポイント
const cachedServerlessExpress = serverlessExpress({ app });
module.exports = async function (event: any, context: any) {
  return cachedServerlessExpress(event, context, null);
};
