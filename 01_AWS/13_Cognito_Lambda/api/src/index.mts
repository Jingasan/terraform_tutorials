import serverlessExpress from "@vendia/serverless-express";
import express from "express";
import cors from "cors";
import bodyParser from "body-parser";
import * as sourceMapSupport from "source-map-support";
import { CognitoClient } from "./cognito.mjs";
sourceMapSupport.install();
const app = express();
// リクエストボディのパース用設定
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));
// CORS
app.use(cors());
// Cognitoクライアント
const cognitoClient = new CognitoClient();
// ユーザープールID
const userPoolId = String(process.env.USER_POOL_ID);
// アプリケーションクライアントID
const applicationClientId = String(process.env.APPLICATION_CLIENT_ID);
// Signup Page
app.get("/signup", async (_req, res) => {
  res.send(`
    <h1>Signup Page</h1>
    <form action="/signup" method="post">
      <input type="text" name="username" placeholder="Username" required><br>
      <input type="email" name="email" placeholder="EMail" required><br>
      <input type="password" name="password" placeholder="Password" required><br>
      <button type="submit">Signup</button>
    </form>
  `);
});
// Signup
app.post("/signup", async (req, res) => {
  const body = req.body;
  if (!body.username)
    return res.status(400).json({ Result: false, Error: "NO_USERNAME" });
  if (!body.email)
    return res.status(400).json({ Result: false, Error: "NO_EMAIL" });
  if (!body.password)
    return res.status(400).json({ Result: false, Error: "NO_PASSWORD" });
  console.log(body);
  // サインアップ
  const result = await cognitoClient.signUp(
    applicationClientId,
    body.username,
    body.email,
    body.password
  );
  console.log(result);
  if (!result)
    return res.status(400).json({ Result: false, Error: "SIGNUP_FAILURE" });
  // サインインページにリダイレクト
  return res.redirect("/confirm");
});
// Confirm Page
app.get("/confirm", async (_req, res) => {
  res.send(`
    <h1>Confirm Signup Page</h1>
    <form action="/confirm" method="post">
      <input type="text" name="username" placeholder="Username" required><br>
      <input type="text" name="code" placeholder="Confirm Code" required><br>
      <button type="submit">Confirm</button>
    </form>
  `);
});
// Confirm
app.post("/confirm", async (req, res) => {
  const body = req.body;
  if (!body.username)
    return res.status(400).json({ Result: false, Error: "NO_USERNAME" });
  if (!body.code)
    return res.status(400).json({ Result: false, Error: "NO_CONFIRM_CODE" });
  console.log(body);
  // サインアップ検証
  const result = await cognitoClient.confirmSignUp(
    applicationClientId,
    body.username,
    body.code
  );
  console.log(result);
  if (!result)
    return res.status(400).json({ Result: false, Error: "CONFIRM_FAILURE" });
  // サインインページにリダイレクト
  return res.redirect("/signin");
});
// Signin Page
app.get("/signin", async (_req, res) => {
  res.send(`
    <h1>Signin Page</h1>
    <form action="/signin" method="post">
      <input type="text" name="username" placeholder="Username" required><br>
      <input type="password" name="password" placeholder="Password" required><br>
      <button type="submit">Signin</button>
    </form>
  `);
});
// Signin
app.post("/signin", async (req, res) => {
  const body = req.body;
  if (!body.username)
    return res.status(400).json({ Result: false, Error: "NO_USERNAME" });
  if (!body.password)
    return res.status(400).json({ Result: false, Error: "NO_PASSWORD" });
  console.log(body);
  // サインイン
  const result = await cognitoClient.initiateAuth(
    applicationClientId,
    body.username,
    body.password
  );
  console.log(result);
  if (!result)
    return res.status(400).json({ Result: false, Error: "SIGNIN_FAILURE" });
  const accessToken = result.AuthenticationResult.AccessToken;
  // メインページにリダイレクト
  return res.redirect("/main/" + accessToken);
});
// Main Page
app.get("/main/:accessToken", async (req, res) => {
  const accessToken = req.params.accessToken;
  res.send(`
    <h1>Main Page</h1>
    <h2>パスワード変更</h2>
    <form action="/changepassword" method="post">
      <input type="text" name="currentPassword" placeholder="CurrentPassword" required><br>
      <input type="text" name="newPassword" placeholder="NewPassword" required><br>
      <input type="text" name="accessToken" placeholder="AccessToken" value="${accessToken}" required><br>
      <button type="submit">ChangePassword</button>
    </form>
    <h2>サインアウト</h2>
    <form action="/signout" method="post">
      <input type="text" name="accessToken" placeholder="AccessToken" value="${accessToken}" required><br>
      <button type="submit">Signout</button>
    </form>
    <h2>退会</h2>
    <form action="/deleteuser" method="post">
      <input type="text" name="accessToken" placeholder="AccessToken" value="${accessToken}" required><br>
      <button type="submit">DeleteUser</button>
    </form>
  `);
});
// ChangePassword
app.post("/changepassword", async (req, res) => {
  const body = req.body;
  if (!body.currentPassword)
    return res
      .status(400)
      .json({ Result: false, Error: "NO_CURRENT_PASSWORD" });
  if (!body.newPassword)
    return res.status(400).json({ Result: false, Error: "NO_NEW_PASSWORD" });
  if (!body.accessToken)
    return res.status(400).json({ Result: false, Error: "NO_ACCESS_TOKEN" });
  console.log(body);
  const result = await cognitoClient.changePassword(
    body.currentPassword,
    body.newPassword,
    body.accessToken
  );
  console.log(result);
  if (!result)
    return res
      .status(400)
      .json({ Result: false, Error: "CHANGE_PASSWORD_FAILURE" });
  // メインページにリダイレクト
  return res.redirect("/main/" + body.accessToken);
});
// Signout
app.post("/signout", async (req, res) => {
  const body = req.body;
  if (!body.accessToken)
    return res.status(400).json({ Result: false, Error: "NO_ACCESS_TOKEN" });
  console.log(body);
  const result = await cognitoClient.globalSignOut(body.accessToken);
  console.log(result);
  if (!result)
    return res.status(400).json({ Result: false, Error: "SIGNOUT_FAILURE" });
  // サインインページにリダイレクト
  return res.redirect("/signin");
});
// DeleteUser
app.post("/deleteuser", async (req, res) => {
  const body = req.body;
  if (!body.accessToken)
    return res.status(400).json({ Result: false, Error: "NO_ACCESS_TOKEN" });
  console.log(body);
  const result = await cognitoClient.deleteUser(body.accessToken);
  console.log(result);
  if (!result)
    return res
      .status(400)
      .json({ Result: false, Error: "DELETE_USER_FAILURE" });
  // サインアップページにリダイレクト
  return res.redirect("/signup");
});
// Error 404 Not Found
app.use((_req, res) => {
  return res.status(404).json({
    error: "Lambda function is called.",
  });
});
// 関数エンドポイント
export const handler = serverlessExpress({ app });
