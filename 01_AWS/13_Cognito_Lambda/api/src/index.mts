import serverlessExpress from "@vendia/serverless-express";
import express from "express";
import cookieSession from "cookie-session";
import { randomUUID } from "crypto";
import cors from "cors";
import bodyParser from "body-parser";
import * as sourceMapSupport from "source-map-support";
import { CognitoClient } from "./cognito.mjs";
sourceMapSupport.install();
const app = express();
// Secure Cookieを発行する場合に必要な設定
app.set("trust proxy", 1);
// リクエストボディのパース用設定
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));
// CORS
app.use(cors());
// Sessionの設定
// cookie-sessionではセッションをすべてCookieに保存する
app.use(
  cookieSession({
    name: "session", // [Option] Cookie名
    keys: [randomUUID()], // [Option] セッションの署名に使用する鍵
    path: "/", // [Option] "/"(default): Cookieを送信するPATH
    httpOnly: true, // [Option] true(default): httpのみで使用, document.cookieを使ってCookieを扱えなくする
    maxAge: 30 * 1000, // [Option] Cookieの有効期限[ms]
    secure: false, // [Option] false(default) trueにすると、HTTPS接続のときのみCookieを発行する
    // trueを設定した場合、「app.set("trust proxy", 1)」を設定する必要がある。
    // Proxy背後にExpressを配置すると、Express自体はHTTPで起動するため、Cookieが発行されないが、
    // これを設定しておくことで、Expressは自身がプロキシ背後に配置されていること、
    // 信頼された「X-Forwarded-*」ヘッダーフィールドであることを認識し、Proxy背後でもCookieを発行するようになる。
  })
);
// Cognitoクライアント
const cognitoClient = new CognitoClient();
// アプリケーションクライアントID
const applicationClientId = String(process.env.APPLICATION_CLIENT_ID);

/**
 * サインアップページ
 */
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

/**
 * サインアップAPI
 */
app.post("/signup", async (req, res) => {
  // リクエストボディチェック
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
  if (!result.result)
    return res
      .status(400)
      .json({ Result: result.result, Error: result.output });

  // サインインページにリダイレクト
  return res.redirect("/confirm");
});

/**
 * サインアップ検証ページ
 */
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

/**
 * サインアップ検証API
 */
app.post("/confirm", async (req, res) => {
  // リクエストボディチェック
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
  if (!result.result)
    return res
      .status(400)
      .json({ Result: result.result, Error: result.output });

  // サインインページにリダイレクト
  return res.redirect("/signin");
});

/**
 * サインインページ
 */
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

/**
 * サインインAPI
 */
app.post("/signin", async (req, res) => {
  // リクエストボディチェック
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
  if (!result.result || typeof result.output === "string")
    return res
      .status(400)
      .json({ Result: result.result, Error: result.output });

  // Cookieにセッションを設定
  req.session.update = Date.now();
  req.session.isAuthenticated = true;
  req.session.user = body.username;
  req.session.accessToken = result.output.AuthenticationResult.AccessToken;

  // メインページにリダイレクト
  return res.redirect("/main");
});

/**
 * メインページ
 */
app.get("/main", async (req, res) => {
  // eslint-disable-next-line @typescript-eslint/no-unsafe-assignment
  const isAuthenticated = req.session.isAuthenticated || false;
  // 未認証時
  if (!isAuthenticated) {
    // サインインページにリダイレクト
    return res.status(401).redirect("/signin");
  } else {
    // セッションの有効期限を更新
    req.session.update = Date.now();
    // eslint-disable-next-line @typescript-eslint/no-unsafe-assignment
    const user = req.session.user;
    // メインページ
    return res.send(`
      <h1>Main Page</h1>
      <div>UserName: ${user}</div>
      <h2>パスワード変更</h2>
      <form action="/changepassword" method="post">
        <input type="text" name="currentPassword" placeholder="CurrentPassword" required><br>
        <input type="text" name="newPassword" placeholder="NewPassword" required><br>
        <button type="submit">ChangePassword</button>
      </form>
      <h2>サインアウト</h2>
      <form action="/signout" method="post">
        <button type="submit">Signout</button>
      </form>
      <h2>退会</h2>
      <form action="/deleteuser" method="post">
        <button type="submit">DeleteUser</button>
      </form>
    `);
  }
});

/**
 * パスワード変更API
 */
app.post("/changepassword", async (req, res) => {
  // eslint-disable-next-line @typescript-eslint/no-unsafe-assignment
  const isAuthenticated = req.session.isAuthenticated || false;
  // 未認証時
  if (!isAuthenticated) {
    // サインインページにリダイレクト
    return res.status(401).redirect("/signin");
  }
  // セッションの有効期限を更新
  req.session.update = Date.now();
  // eslint-disable-next-line @typescript-eslint/no-unsafe-assignment
  const accessToken = req.session.accessToken;

  // リクエストボディチェック
  const body = req.body;
  if (!body.currentPassword)
    return res
      .status(400)
      .json({ Result: false, Error: "NO_CURRENT_PASSWORD" });
  if (!body.newPassword)
    return res.status(400).json({ Result: false, Error: "NO_NEW_PASSWORD" });
  console.log(body);

  // パスワード変更
  const result = await cognitoClient.changePassword(
    body.currentPassword,
    body.newPassword,
    accessToken
  );
  console.log(result);
  if (!result.result)
    return res
      .status(400)
      .json({ Result: result.result, Error: result.output });

  // メインページにリダイレクト
  return res.redirect("/main");
});

/**
 * サインアウトAPI
 */
app.post("/signout", async (req, res) => {
  // eslint-disable-next-line @typescript-eslint/no-unsafe-assignment
  const isAuthenticated = req.session.isAuthenticated || false;
  // 未認証時
  if (!isAuthenticated) {
    // サインインページにリダイレクト
    return res.status(401).redirect("/signin");
  }
  // eslint-disable-next-line @typescript-eslint/no-unsafe-assignment
  const accessToken = req.session.accessToken;

  // サインアウト
  const result = await cognitoClient.globalSignOut(accessToken);
  console.log(result);
  if (!result.result)
    return res
      .status(400)
      .json({ Result: result.result, Error: result.output });

  // セッションをクリア
  req.session = null;

  // サインインページにリダイレクト
  return res.redirect("/signin");
});

/**
 * ユーザー削除API
 */
app.post("/deleteuser", async (req, res) => {
  // eslint-disable-next-line @typescript-eslint/no-unsafe-assignment
  const isAuthenticated = req.session.isAuthenticated || false;
  // 未認証時
  if (!isAuthenticated) {
    // サインインページにリダイレクト
    return res.status(401).redirect("/signin");
  }
  // eslint-disable-next-line @typescript-eslint/no-unsafe-assignment
  const accessToken = req.session.accessToken;

  // ユーザー削除
  const result = await cognitoClient.deleteUser(accessToken);
  console.log(result);
  if (!result.result)
    return res
      .status(400)
      .json({ Result: result.result, Error: result.output });

  // セッションをクリア
  req.session = null;

  // サインアップページにリダイレクト
  return res.redirect("/signup");
});

/**
 * Error 404 Not Found
 */
app.use((_req, res) => {
  return res.status(404).json({
    error: "Lambda function is called.",
  });
});

/**
 * 関数エンドポイント
 */
export const handler = serverlessExpress({ app });
