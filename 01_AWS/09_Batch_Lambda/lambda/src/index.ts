import serverlessExpress from "@vendia/serverless-express";
import express, { Application, Request, Response, NextFunction } from "express";
import cors from "cors";
import bodyParser from "body-parser";
import * as sourceMapSupport from "source-map-support";
import * as Batch from "@aws-sdk/client-batch";
sourceMapSupport.install();
const app: Application = express();
const batchClient = new Batch.BatchClient();
// リクエストボディのパース用設定
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));
// CORS
app.use(cors());

// RDS関連の情報
const jobQueue = String(process.env.JOB_QUEUE); // ジョブキュー
const jobDefinition = String(process.env.JOB_DEFINITION); // ジョブ定義

// キューへのジョブの送信
const submitJobCommand = async (
  input: Batch.SubmitJobCommandInput
): Promise<Batch.SubmitJobCommandOutput | false> => {
  const jobCommand = new Batch.SubmitJobCommand(input);
  try {
    const response = await batchClient.send(jobCommand);
    console.log(response);
    return response;
  } catch (e) {
    console.error(e);
    return false;
  }
};

// 送信したジョブのキャンセル
const cancelJobCommand = async (jobId: string): Promise<boolean> => {
  const input: Batch.CancelJobCommandInput = {
    jobId: jobId,
    reason: "Cancelling job.",
  };
  const command = new Batch.CancelJobCommand(input);
  try {
    const response = await batchClient.send(command);
    console.log(response);
    return true;
  } catch (e) {
    console.error(e);
    return false;
  }
};

// ジョブ登録
app.post("/job", async (_req: Request, res: Response, _next: NextFunction) => {
  console.log("JobQueue: " + jobQueue);
  console.log("JobDefinition: " + jobDefinition);
  const input: Batch.SubmitJobCommandInput = {
    jobName: "test-job",
    jobDefinition: jobDefinition,
    jobQueue: jobQueue,
    containerOverrides: {
      command: ["echo", "hello world"],
      environment: [{ name: "NAME", value: "VALUE" }],
      resourceRequirements: [
        { type: "MEMORY", value: "512" },
        { type: "VCPU", value: "0.25" },
      ],
    },
  };
  // キューへのジョブの送信
  const response = await submitJobCommand(input);
  if (!response || !response.jobId) {
    return res.status(503).json("Internal Server Error");
  }
  return res.status(200).json({ jobId: response.jobId });
});

// ジョブキャンセル
app.delete("/job", async (req: Request, res: Response, _next: NextFunction) => {
  const jobId = String(req.query?.jobId);
  if (!jobId) {
    return res.status(503).json("Internal Server Error");
  }
  // 送信したジョブのキャンセル
  const response = await cancelJobCommand(jobId);
  if (!response) {
    return res.status(503).json("Internal Server Error");
  }
  return res.status(200).json("OK");
});

// 関数のエンドポイント
export const handler = serverlessExpress({ app });
