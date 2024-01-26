import * as functions from "@google-cloud/functions-framework";
import express from "express";
import cors from "cors";
import { GCRJobClient } from "./cloudrun.mjs";
const app = express();
const gcrJobClient = new GCRJobClient();
const projectId = String(process.env.PROJECT_ID);
const region = String(process.env.REGION);
// リクエストボディのパース用設定
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
// CORSの設定
app.use(cors());
// ジョブの実行
app.post("/job_run", async (req, res) => {
  if (!req.body.jobId) return res.status(400).json("No Job ID");
  const jobId = String(req.body.jobId);
  await gcrJobClient.runJob(jobId);
  return res.status(200).json("OK");
});
// ジョブ一覧取得
app.post("/job_list", async (_req, res) => {
  const list = await gcrJobClient.listJobs(projectId, region);
  return res.status(200).json(list);
});
// ジョブの実行中タスク一覧の取得
app.post("/job_task_list", async (req, res) => {
  if (!req.body.jobId) return res.status(400).json("No Job ID");
  const jobId = String(req.body.jobId);
  const list = await gcrJobClient.listJobTask(jobId);
  return res.status(200).json(list);
});
// ジョブの実行中タスクの中断
app.post("/job_task_cancel", async (req, res) => {
  if (!req.body.taskId) return res.status(400).json("No Job Task ID");
  const taskId = String(req.body.taskId);
  await gcrJobClient.cancelJobTask(taskId);
  return res.status(200).json("OK");
});
// Error 404 Not Found
app.use((_req, res) => {
  return res.status(404).json({ error: "Not Found" });
});
// 関数のエンドポイント
functions.http("api", app);
