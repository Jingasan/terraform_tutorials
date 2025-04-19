import serverlessExpress from "@vendia/serverless-express";
import express, { Request, Response, NextFunction } from "express";
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
    maxAge: Number(process.env.SESSION_TIMEOUT) * 1000, // [Option] Cookieの有効期限[ms]
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
    <h1>サインアップ画面</h1>
    <form action="/signup" method="post">
      <input type="text" name="username" placeholder="Username" required><br/>
      <input type="email" name="email" placeholder="email@domain" required><br/>
      <input type="password" name="password" placeholder="Password" required><br/>
      <button type="submit">新規登録</button>
    </form>
    <a href="/signin">ログイン</a>
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
    body.email,
    body.email,
    body.username,
    body.password
  );
  console.log(JSON.stringify(result, null, "  "));
  if (!result.res)
    return res.status(400).json({
      error: { name: result.error.name, message: result.error.message },
    });

  // サインインページにリダイレクト
  return res.status(302).redirect("/confirm");
});

/**
 * サインアップ検証ページ
 */
app.get("/confirm", async (_req, res) => {
  res.send(`
    <h1>サインアップ検証画面</h1>
    <form action="/confirm" method="post">
      <input type="email" name="email" placeholder="email@domain" required><br/>
      <input type="text" name="code" placeholder="Confirm Code" required><br/>
      <button type="submit">検証</button>
    </form>
    <a href="/signin">ログイン</a>
  `);
});

/**
 * サインアップ検証API
 */
app.post("/confirm", async (req, res) => {
  // リクエストボディチェック
  const body = req.body;
  if (!body.email)
    return res.status(400).json({ Result: false, Error: "NO_EMAIL" });
  if (!body.code)
    return res.status(400).json({ Result: false, Error: "NO_CONFIRM_CODE" });
  console.log(body);

  // サインアップ検証
  const result = await cognitoClient.confirmSignUp(
    applicationClientId,
    body.email,
    body.code
  );
  console.log(result);
  if (!result.res)
    return res.status(400).json({
      error: { name: result.error.name, message: result.error.message },
    });

  // サインインページにリダイレクト
  return res.status(302).redirect("/signin");
});

/**
 * サインインページ
 */
app.get("/", async (_req, res) => {
  return res.status(302).redirect("/signin");
});
app.get("/signin", async (_req, res) => {
  res.send(`
    <h1>ログイン画面</h1>
    <form action="/signin" method="post">
      <input type="email" name="email" placeholder="email@domain" required><br/>
      <input type="password" name="password" placeholder="Password" required><br/>
      <button type="submit">ログイン</button>
    </form>
    <a href="/signup">新規登録</a>
  `);
});

/**
 * サインインAPI
 */
app.post("/signin", async (req, res) => {
  // リクエストボディチェック
  const body = req.body;
  if (!body.email)
    return res.status(400).json({ Result: false, Error: "NO_EMAIL" });
  if (!body.password)
    return res.status(400).json({ Result: false, Error: "NO_PASSWORD" });
  console.log(body);

  // サインイン
  const result = await cognitoClient.initiateAuth(
    applicationClientId,
    body.email,
    body.password
  );
  console.log(JSON.stringify(result, null, "  "));
  if (!result.res)
    return res.status(400).json({
      error: { name: result.error.name, message: result.error.message },
    });

  // Cookieにセッションを設定
  // Cookieの上限容量は4096Byte以内であるため、アクセストークンとリフレッシュトークンのみを格納する
  req.session.accessToken = result.res.AuthenticationResult.AccessToken;
  req.session.refreshToken = result.res.AuthenticationResult.RefreshToken;

  // メインページにリダイレクト
  return res.status(302).redirect("/user");
});

/**
 * IDトークン／アクセストークンの更新
 * @param req
 * @param res
 * @param next
 * @returns
 */
const updateToken = async (req: Request, res: Response, next: NextFunction) => {
  const refreshToken = req.session.refreshToken || false;
  // 未認証時
  if (!refreshToken) {
    // サインインページにリダイレクト
    return res.status(302).redirect("/signin");
  }

  // IDトークン／アクセストークンの更新
  const result = await cognitoClient.updateToken(
    applicationClientId,
    refreshToken
  );
  console.log(JSON.stringify(result, null, "  "));
  // 更新失敗時
  if (!result.res) {
    // サインインページにリダイレクト
    return res.status(302).redirect("/signin");
  }

  // セッションのアクセストークンを更新
  req.session.accessToken = result.res.AuthenticationResult.AccessToken;
  next();
};

/**
 * メインページ
 */
app.get("/user", updateToken, async (req, res) => {
  // eslint-disable-next-line @typescript-eslint/no-unsafe-assignment
  const accessToken = req.session.accessToken || false;
  // 未認証時
  if (!accessToken) {
    // サインインページにリダイレクト
    return res.status(401).redirect("/signin");
  }

  // ユーザー属性データの取得
  const userData = await cognitoClient.getUserData(accessToken);
  console.log(JSON.stringify(userData, null, "  "));
  if (!userData.res)
    return res.status(400).json({
      error: { name: userData.error.name, message: userData.error.message },
    });
  const userAttributes = {};
  for (const attr of userData.res.UserAttributes) {
    userAttributes[attr.Name] = attr.Value;
  }

  // ユーザー画面
  return res.send(`
    <h1>ユーザー画面</h1>
    <table>
      <tbody>
        <tr><td>ログインユーザー名：</td><td>${userAttributes["name"]}</td></tr>
        <tr><td>メールアドレス：</td><td>${userAttributes["email"]}</td></tr>
        <tr>
          <td>リフレッシュトークン：</td>
          <td><input type="text" value="${req.session.refreshToken}" size=50 /></td>
        </tr>
        <tr>
          <td>アクセストークン：</td>
          <td><input type="text" value="${req.session.accessToken}" size=50 /></td>
        </tr>
      </tbody>
    </table>
    <h2>パスワード変更</h2>
    <form action="/changepassword" method="post">
      <input type="text" name="currentPassword" placeholder="現在のパスワード" required><br/>
      <input type="text" name="newPassword" placeholder="新しいパスワード" required><br/>
      <button type="submit">変更</button>
    </form>
    <h2>サインアウト</h2>
    <form action="/signout" method="post">
      <button type="submit">サインアウト</button>
    </form>
    <h2>退会</h2>
    <form action="/deleteuser" method="post">
      <button type="submit">退会</button>
    </form>
  `);
});

/**
 * パスワード変更API
 */
app.post("/changepassword", updateToken, async (req, res) => {
  // eslint-disable-next-line @typescript-eslint/no-unsafe-assignment
  const accessToken = req.session.accessToken || false;
  // 未認証時
  if (!accessToken) {
    // サインインページにリダイレクト
    return res.status(401).redirect("/signin");
  }
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
  if (!result.res)
    return res.status(400).json({
      error: { name: result.error.name, message: result.error.message },
    });

  // メインページにリダイレクト
  return res.redirect("/user");
});

/**
 * サインアウトAPI
 */
app.post("/signout", async (req, res) => {
  // eslint-disable-next-line @typescript-eslint/no-unsafe-assignment
  const accessToken = req.session.accessToken || false;
  // 未認証時
  if (!accessToken) {
    // サインインページにリダイレクト
    return res.status(302).redirect("/signin");
  }

  // サインアウト
  const result = await cognitoClient.globalSignOut(accessToken);
  console.log(result);
  if (!result.result)
    return res.status(400).json({
      error: { name: result.error.name, message: result.error.message },
    });

  // セッションをクリア
  req.session = null;

  // サインインページにリダイレクト
  return res.status(302).redirect("/signin");
});

/**
 * ユーザー削除API
 */
app.post("/deleteuser", async (req, res) => {
  // eslint-disable-next-line @typescript-eslint/no-unsafe-assignment
  const accessToken = req.session.accessToken || false;
  // 未認証時
  if (!accessToken) {
    // サインインページにリダイレクト
    return res.status(302).redirect("/signin");
  }

  // ユーザー削除
  const result = await cognitoClient.deleteUser(accessToken);
  console.log(result);
  if (!result.result)
    return res.status(400).json({
      error: { name: result.error.name, message: result.error.message },
    });

  // セッションをクリア
  req.session = null;

  // サインアップページにリダイレクト
  return res.status(302).redirect("/signup");
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
