import * as functions from "@google-cloud/functions-framework";
import express, { Request, Response } from "express";
import cors from "cors";
import { randomUUID } from "crypto";
import { GCSClient } from "./gcs.mjs";
const gcsClient = new GCSClient();
const app = express();
// リクエストボディのパース用設定
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
// CORSの設定
app.use(cors());
// GCSバケット名
const bucket = String(process.env.BUCKET);
// Put用PresignedURLの取得
app.get("/presignedurl", async (_req: Request, res: Response) => {
  const path = randomUUID().toString() + ".json";
  const expires = 24 * 60 * 60; // 24h
  const objectList = await gcsClient.getPutPresignedURL(bucket, path, expires);
  return res.status(200).json(objectList);
});
// オブジェクト一覧取得API
app.get("/object_list", async (_req: Request, res: Response) => {
  const objectList = await gcsClient.listObjects(bucket);
  return res.status(200).json(objectList);
});
// オブジェクトの作成API
app.post("/object", async (req: Request, res: Response) => {
  const dstpath = randomUUID().toString() + ".json";
  const object = JSON.stringify(req.body);
  const result = await gcsClient.putObject(bucket, dstpath, object);
  if (!result) return res.status(500).json("Internal Server Error");
  return res.status(200).json({ file: dstpath });
});
// オブジェクトの取得API
app.get("/object", async (req: Request, res: Response) => {
  if (!req.query?.file) return res.status(400).json("NO_FILE_QUERY");
  const result = await gcsClient.getObject(bucket, String(req.query.file));
  if (!result) return res.status(500).json("Internal Server Error");
  return res.status(200).json(JSON.parse(result));
});
// オブジェクトの作成API
app.delete("/object", async (req: Request, res: Response) => {
  if (!req.query?.file) return res.status(400).json("NO_FILE_QUERY");
  const result = await gcsClient.deleteObject(bucket, String(req.query.file));
  if (!result) return res.status(500).json("Internal Server Error");
  return res.status(200).json("OK");
});
// Error 404 Not Found
app.use((_req: Request, res: Response) => {
  console.log(`Bucket: ${bucket}`);
  console.log(JSON.parse(process.env.CREDENTIALS));
  return res.status(404).json({ error: "Not Found" });
});
// 関数のエンドポイント
functions.http("api", app);
