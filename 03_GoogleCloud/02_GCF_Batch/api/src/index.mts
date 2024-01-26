import * as functions from "@google-cloud/functions-framework";
import express from "express";
import cors from "cors";
import { BatchClient } from "./batch.mjs";
const app = express();
const batchClient = new BatchClient();
const projectId = String(process.env.PROJECT_ID);
const region = String(process.env.REGION);
// リクエストボディのパース用設定
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
// CORSの設定
app.use(cors());
// ジョブの作成
app.post("/create", async (_req, res) => {
  const jobId = await batchClient.createJob(projectId, region);
  if (!jobId) return res.status(500).json("Internal Server Error");
  return res.status(200).json({ JobID: jobId });
});
// ジョブの一覧取得
app.post("/list", async (_req, res) => {
  const list = await batchClient.listJobs(projectId, region);
  return res.status(200).json(list);
});
// ジョブ情報の取得
app.post("/jobinfo", async (req, res) => {
  if (!req.body.jobId) return res.status(400).json("No Job ID");
  const jobId = String(req.body.jobId);
  const jobInfo = await batchClient.getJobInfo(jobId);
  return res.status(200).json(jobInfo);
});
// ジョブの削除
app.post("/delete", async (req, res) => {
  if (!req.body.jobId) return res.status(400).json("No Job ID");
  const jobId = String(req.body.jobId);
  await batchClient.deleteJob(jobId);
  return res.status(200).json("OK");
});
// Error 404 Not Found
app.use((_req, res) => {
  return res.status(404).json({ error: "Not Found" });
});
// 関数のエンドポイント
functions.http("api", app);
