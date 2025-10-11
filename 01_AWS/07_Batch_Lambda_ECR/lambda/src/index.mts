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

// AWS Batch関連の情報
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

// 連続ジョブの登録
app.get("/job", async (_req: Request, res: Response, _next: NextFunction) => {
  console.log("JobQueue: " + jobQueue);
  console.log("JobDefinition: " + jobDefinition);
  // ジョブ１の送信
  const input1: Batch.SubmitJobCommandInput = {
    jobName: "test-job-1",
    jobDefinition: jobDefinition,
    jobQueue: jobQueue,
    containerOverrides: {
      command: ["sleep", "10"],
      environment: [{ name: "NAME", value: "VALUE" }],
      resourceRequirements: [
        { type: "MEMORY", value: "512" },
        { type: "VCPU", value: "0.25" },
      ],
    },
  };
  const response1 = await submitJobCommand(input1);
  if (!response1 || !response1.jobId) {
    return res.status(500).json("Internal Server Error");
  }
  // ジョブ２の送信
  const input2: Batch.SubmitJobCommandInput = {
    jobName: "test-job-2",
    jobDefinition: jobDefinition,
    jobQueue: jobQueue,
    containerOverrides: {
      command: ["sleep", "10"],
      environment: [{ name: "NAME", value: "VALUE" }],
      resourceRequirements: [
        { type: "MEMORY", value: "512" },
        { type: "VCPU", value: "0.25" },
      ],
    },
    dependsOn: [{ jobId: response1.jobId, type: "N_TO_N" }],
  };
  const response2 = await submitJobCommand(input2);
  if (!response2 || !response2.jobId) {
    return res.status(500).json("Internal Server Error");
  }
  // ジョブ３の送信
  const input3: Batch.SubmitJobCommandInput = {
    jobName: "test-job-3",
    jobDefinition: jobDefinition,
    jobQueue: jobQueue,
    containerOverrides: {
      command: ["sleep", "10"],
      environment: [{ name: "NAME", value: "VALUE" }],
      resourceRequirements: [
        { type: "MEMORY", value: "512" },
        { type: "VCPU", value: "0.25" },
      ],
    },
    dependsOn: [{ jobId: response2.jobId, type: "N_TO_N" }],
  };
  const response3 = await submitJobCommand(input3);
  if (!response3 || !response3.jobId) {
    return res.status(500).json("Internal Server Error");
  }
  // レスポンス
  return res
    .status(200)
    .json([
      { job1Id: response1.jobId },
      { job2Id: response2.jobId },
      { job3Id: response3.jobId },
    ]);
});

// ジョブキャンセル
app.delete("/job", async (req: Request, res: Response, _next: NextFunction) => {
  const jobId = String(req.query?.jobId); // キャンセルするジョブID
  if (!jobId) {
    return res.status(500).json("Internal Server Error");
  }
  // 送信したジョブのキャンセル
  const response = await cancelJobCommand(jobId);
  if (!response) {
    return res.status(500).json("Internal Server Error");
  }
  return res.status(200).json("OK");
});

// 関数のエンドポイント
export const handler = serverlessExpress({ app });
