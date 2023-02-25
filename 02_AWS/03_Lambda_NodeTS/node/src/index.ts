import serverlessExpress from "@vendia/serverless-express";
import express from "express";
import cors from "cors";
import bodyParser from "body-parser";
import * as sourceMapSupport from "source-map-support";
sourceMapSupport.install();
const app = express();
const router = express.Router();
router.use(bodyParser.json());
router.use(bodyParser.urlencoded({ extended: true }));
// CORS
const corsOptions = {
  origin: "*",
  methods: "GET, POST, PUT, DELETE",
  allowedHeaders:
    "Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token",
};
// GET
app.get("/users/:id", cors(corsOptions), (req, res, _next) => {
  return res.status(200).json({ Query: req.query });
});
// POST
app.post("/users/:id", cors(corsOptions), (req, res, _next) => {
  const body = JSON.parse(req.body);
  return res.status(200).json({ PostBody: body });
});
// PUT
app.put("/users/:id", cors(corsOptions), (req, res, _next) => {
  return res.status(200).json({ RequestHeader: req.headers });
});
// DELETE
app.delete("/users/:id", cors(corsOptions), (req, res, _next) => {
  return res.status(200).json({ URLParams: req.params.id });
});
// Error 404 Not Found
app.use(cors(corsOptions), (_req, res, _next) => {
  return res.status(404).json({
    error: "Not Found",
  });
});
app.use("/", router);
export const handler = serverlessExpress({ app });
