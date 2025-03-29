import * as sourceMapSupport from "source-map-support";
import * as Cognito from "@aws-sdk/client-cognito-identity-provider";
import express, { Request, Response, NextFunction } from "express";
import session from "express-session";
import cors from "cors";
import * as dotenv from "dotenv";
import { randomUUID } from "crypto";
import { CognitoClient } from "./cognite.mjs";
sourceMapSupport.install();
dotenv.config();
const app = express();
const PORT = 3000;
// リージョン
const REGION = process.env.REGION || "ap-northeast-1";
// ユーザープールID
const USER_POOL_ID = String(process.env.USER_POOL_ID);
// アプリケーションクライアントID
const APPLICATION_CLIENT_ID = String(process.env.APPLICATION_CLIENT_ID);
// Cognitoクライアント
const cognitoClient = new CognitoClient(REGION);
// Secure Cookieを発行する場合に必要な設定
app.set("trust proxy", 1);
// リクエストボディのパース設定
// 1. JSON形式のリクエストボディをパースできるように設定
// 2. フォームの内容をパースできるように設定
// 3. Payload Too Large エラー対策：50MBまでのデータをPOSTできるように設定(default:100kb)
app.use(express.json({ limit: "50mb" }));
app.use(express.urlencoded({ limit: "50mb", extended: true }));
// CORS設定
app.use(cors());
// Sessionの設定
app.use(
  session({
    secret: randomUUID(), // [Must] セッションIDを保存するCookieの署名に使用される, ランダムな値にすることを推奨
    name: "session", // [Option] Cookie名, connect.id(default)(変更推奨)
    rolling: true, // [Option] アクセス時にセッションの有効期限をリセットする
    resave: false, // [Option] true(default):リクエスト中にセッションが変更されなかった場合でも強制的にセッションストアに保存し直す
    saveUninitialized: false, // [Option] true(default): 初期化されていないセッションを強制的にセッションストアに保存する
    cookie: {
      path: "/", // [Option] "/"(default): Cookieを送信するPATH
      httpOnly: true, // [Option] true(default): httpのみで使用, document.cookieを使ってCookieを扱えなくする
      maxAge: 300 * 1000, // [Option] Cookieの有効期限[ms]
      secure: "auto", // [Option] auto(default): trueにすると、HTTPS接続のときのみCookieを発行する
      // trueを設定した場合、「app.set("trust proxy", 1)」を設定する必要がある。
      // Proxy背後にExpressを配置すると、Express自体はHTTPで起動するため、Cookieが発行されないが、
      // これを設定しておくことで、Expressは自身がプロキシ背後に配置されていること、
      // 信頼された「X-Forwarded-*」ヘッダーフィールドであることを認識し、Proxy背後でもCookieを発行するようになる。
    },
  })
);

// セッションで扱うデータ（SessionData）の型宣言
declare module "express-session" {
  interface SessionData {
    cognitoSession?: string;
    username?: string;
    challengeName?: Cognito.ChallengeNameType;
    accessToken?: string;
    refreshToken?: string;
    isAuthenticated: boolean;
    cart: string[];
  }
}

/**
 * 管理者ページ
 */
app.get("/admin", async (_req, res) => {
  // ユーザー情報一覧取得
  const result = await cognitoClient.listAllUsers({
    userPoolId: USER_POOL_ID,
  });
  if (!result.res)
    return res.status(400).json({
      error: { name: result.error.name, message: result.error.message },
    });
  let sendPage = `
    <h1>管理者画面</h1>
    <h2>新規ユーザー登録</h2>
    <form action="/create_user" method="post">
      <input type="email" name="email" placeholder="email@domain" required><br/>
      <input type="text" name="usageStartDate" placeholder="利用開始日(yyyy-MM-dd)"><br/>
      <input type="text" name="usageEndDate" placeholder="利用終了日(yyyy-MM-dd)"><br/>
      <button type="submit">新規登録</button>
    </form>
    <h2>ユーザー一覧</h2>
    <table>
      <thead>
        <tr>
          <th>ユーザー名</th>
          <th>メールアドレス</th>
          <th>パスワード設定日</th>
          <th>利用開始日</th>
          <th>利用終了日</th>
          <th>ユーザーステータス</th>
        </tr>
      </thead>
      <tbody>`;
  sendPage += result.res.map((user) => {
    return `<tr>
      <td>${user.Username}</td>
      <td>${
        user.Attributes.find((attr) => attr.Name === "email")?.Value || "未登録"
      }</td>
      <td>${
        user.Attributes.find((attr) => attr.Name === "custom:password_set_date")
          ?.Value || "未登録"
      }</td>
      <td>${
        user.Attributes.find((attr) => attr.Name === "custom:usage_start_date")
          ?.Value || "未登録"
      }</td>
      <td>${
        user.Attributes.find((attr) => attr.Name === "custom:usage_end_date")
          ?.Value || "未登録"
      }</td>
      <td>${user.UserStatus}</td>
    </tr>`;
  });
  sendPage += `</tbody></table>
    <h2>仮パスワード再発行</h2>
    <form action="/resend_temporary_password" method="post">
      <input type="email" name="email" placeholder="email@domain" required><br/>
      <button type="submit">再発行</button>
    </form>
    <h2>ユーザー削除</h2>
    <form action="/admin_delete_user" method="post">
      <input type="email" name="email" placeholder="email@domain" required><br/>
      <button type="submit">削除</button>
    </form>
    <a href="/signin">ログイン画面</a><br/>
  `;
  res.send(sendPage);
});

/**
 * 新規ユーザー作成
 */
app.post("/create_user", async (req, res) => {
  // リクエストボディチェック
  const body = req.body;
  if (!body.email)
    return res.status(400).json({ Result: false, Error: "NO_EMAIL" });
  console.log(body);

  // ユーザー属性を指定
  const userAttributes: Cognito.AttributeType[] = [];
  userAttributes.push({ Name: "email", Value: body.email });
  userAttributes.push({ Name: "email_verified", Value: "true" }); // メールアドレス検証を行う場合はtrueにしない

  // 新規ユーザー作成
  const result = await cognitoClient.adminCreateUser({
    userPoolId: USER_POOL_ID,
    username: body.email,
    usageStartDate: body.usageStartDate,
    usageEndDate: body.usageEndDate,
    userAttributes: userAttributes,
  });
  console.log(JSON.stringify(result, null, 2));
  if (!result.res)
    return res.status(400).json({
      error: { name: result.error.name, message: result.error.message },
    });

  return res.status(302).redirect("/admin");
});

/**
 * 仮パスワードの再発行
 */
app.post("/resend_temporary_password", async (req, res) => {
  // リクエストボディチェック
  const body = req.body;
  if (!body.email)
    return res.status(400).json({ Result: false, Error: "NO_EMAIL" });
  console.log(body);

  // 仮パスワード再発行
  const result = await cognitoClient.resendTemporaryPassword({
    userPoolId: USER_POOL_ID,
    username: body.email,
  });
  console.log(JSON.stringify(result, null, 2));
  if (!result.res)
    return res.status(400).json({
      error: { name: result.error.name, message: result.error.message },
    });

  return res.status(302).redirect("/admin");
});

/**
 * ユーザー削除
 */
app.post("/admin_delete_user", async (req, res) => {
  // リクエストボディチェック
  const body = req.body;
  if (!body.email)
    return res.status(400).json({ Result: false, Error: "NO_EMAIL" });
  console.log(body);

  // ユーザー削除
  const result = await cognitoClient.adminDeleteUser(USER_POOL_ID, body.email);
  console.log(JSON.stringify(result, null, 2));
  if (!result.res)
    return res.status(400).json({
      error: { name: result.error.name, message: result.error.message },
    });

  return res.status(302).redirect("/admin");
});

/**
 * サインアップページ
 */
app.get("/signup", async (_req, res) => {
  res.send(`
    <h1>サインアップ画面</h1>
    <form action="/signup" method="post">
      <input type="email" name="email" placeholder="email@domain" required><br/>
      <input type="password" name="password" placeholder="Password" required><br/>
      <button type="submit">新規登録</button>
    </form>
    <a href="/signin">ログイン画面</a>
  `);
});

/**
 * サインアップAPI
 */
app.post("/signup", async (req, res) => {
  // リクエストボディチェック
  const body = req.body;
  if (!body.password)
    return res.status(400).json({ Result: false, Error: "NO_PASSWORD" });
  if (!body.email)
    return res.status(400).json({ Result: false, Error: "NO_EMAIL" });
  console.log(body);

  // ユーザー属性を指定
  const userAttributes: Cognito.AttributeType[] = [];
  userAttributes.push({ Name: "email", Value: body.email });

  // サインアップ
  const result = await cognitoClient.signUp({
    userPoolClientId: APPLICATION_CLIENT_ID,
    password: body.password,
    username: body.email,
    userAttributes: userAttributes,
  });
  console.log(JSON.stringify(result, null, 2));
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
    <a href="/signin">ログイン画面</a>
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
    APPLICATION_CLIENT_ID,
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
    <a href="/signup">サインアップ</a><br/>
    <a href="/forgot_password">パスワードを忘れた場合</a><br/>
    <a href="/admin">管理者画面</a><br/>
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

  // サインイン(一段階目)
  const result = await cognitoClient.auth1st(
    APPLICATION_CLIENT_ID,
    body.email,
    body.password
  );
  if (!result.res)
    return res.status(400).json({
      error: { name: result.error.name, message: result.error.message },
    });

  // サインイン(二段階)
  const result2 = await cognitoClient.auth2nd(
    APPLICATION_CLIENT_ID,
    body.email
  );
  if (!result2.res)
    return res.status(400).json({
      error: { name: result2.error.name, message: result2.error.message },
    });

  if (result2.res.ChallengeName === "CUSTOM_CHALLENGE") {
    req.session.cognitoSession = result2.res.Session;
    req.session.username = body.email;
    req.session.challengeName = result2.res.ChallengeName;
    return res.status(302).redirect("/response_to_auth_challenge");
  } else {
    // Cookieにセッションを設定
    // Cookieの上限容量は4096Byte以内であるため、アクセストークンとリフレッシュトークンのみを格納する
    req.session.accessToken = result.res.AuthenticationResult.AccessToken;
    req.session.refreshToken = result.res.AuthenticationResult.RefreshToken;
  }

  // メインページにリダイレクト
  return res.status(302).redirect("/user");
});

/**
 * 二段階認証ページ
 */
app.get("/response_to_auth_challenge", async (_req, res) => {
  res.send(`
    <h1>二段階認証画面</h1>
    <form action="/response_to_auth_challenge" method="post">
      <input type="password" name="code" placeholder="Code" required><br/>
      <button type="submit">認証</button>
    </form>
    <a href="/signin">ログイン画面</a>
  `);
});

/**
 * パスワード変更ページ
 */
app.get("/set_new_password", async (_req, res) => {
  res.send(`
    <h1>パスワード変更画面</h1>
    <form action="/set_new_password" method="post">
      <input type="password" name="newPassword" placeholder="新しいパスワード" required><br/>
      <button type="submit">変更</button>
    </form>
    <a href="/signin">ログイン画面</a>
  `);
});

app.post("/set_new_password", async (req, res) => {
  // リクエストボディチェック
  const body = req.body;
  if (!body.newPassword)
    return res.status(400).json({ Result: false, Error: "NO_NEW_PASSWORD" });
  console.log(body);

  // パスワード変更
  const result = await cognitoClient.adminSetUserPassword(
    USER_POOL_ID,
    req.session.username,
    body.newPassword
  );
  console.log(result);
  if (!result.res)
    return res.status(400).json({
      error: { name: result.error.name, message: result.error.message },
    });

  // メインページにリダイレクト
  return res.status(302).redirect("/user");
});

/**
 * 認証チャレンジに対する回答API
 */
app.post("/response_to_auth_challenge", async (req, res) => {
  // リクエストボディチェック
  const body = req.body;
  if (!body.code)
    return res.status(400).json({ Result: false, Error: "NO_CODE" });
  console.log(body);

  const username = req.session.username;
  const challengeName = req.session.challengeName;
  const cognitoSession = req.session.cognitoSession;
  if (!username || !challengeName || !cognitoSession)
    return res.status(400).json({ Result: false, Error: "SESSION_EXPIRED" });

  // 認証チャレンジに対する回答
  const result = await cognitoClient.respondToAuthChallenge(
    APPLICATION_CLIENT_ID,
    challengeName,
    username,
    body.code,
    cognitoSession
  );
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
 * メールアドレス検証ページ
 */
app.get("/confirm_verify_email", async (_req, res) => {
  res.send(`
    <h1>メールアドレス検証画面</h1>
    <form action="/confirm_verify_email" method="post">
      <input type="password" name="confirmationCode" placeholder="検証コード" required><br/>
      <button type="submit">検証</button>
    </form>
    <a href="/signin">ログイン画面</a>
  `);
});

/**
 * メールアドレス検証
 */
app.post("/confirm_verify_email", async (req, res) => {
  // リクエストボディチェック
  const body = req.body;
  if (!body.confirmationCode)
    return res
      .status(400)
      .json({ Result: false, Error: "NO_CONFIRMATION_CODE" });
  console.log(body);

  // パスワード変更
  const result = await cognitoClient.confirmVerifyEmail(
    req.session.accessToken,
    body.confirmationCode
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
 * パスワードリセットページ
 */
app.get("/forgot_password", async (_req, res) => {
  res.send(`
    <h1>パスワードリセット画面</h1>
    <form action="/forgot_password" method="post">
      <input type="email" name="email" placeholder="email@domain" required><br/>
      <button type="submit">リセット</button>
    </form>
    <a href="/signin">ログイン画面</a>
  `);
});

/**
 * パスワードリセットAPI
 */
app.post("/forgot_password", async (req, res) => {
  // リクエストボディチェック
  const body = req.body;
  if (!body.email)
    return res.status(400).json({ Result: false, Error: "NO_EMAIL" });
  console.log(body);

  // パスワード変更
  const result = await cognitoClient.forgotPassword(
    APPLICATION_CLIENT_ID,
    body.email
  );
  console.log(result);
  if (!result.res)
    return res.status(400).json({
      error: { name: result.error.name, message: result.error.message },
    });

  // パスワードリセットの検証ページにリダイレクト
  return res.redirect("/confirm_forgot_password");
});

/**
 * パスワードリセットページ
 */
app.get("/confirm_forgot_password", async (_req, res) => {
  res.send(`
    <h1>パスワードリセット画面</h1>
    <form action="/confirm_forgot_password" method="post">
      <input type="email" name="email" placeholder="email@domain" required><br/>
      <input type="password" name="confirmationCode" placeholder="検証コード" required><br/>
      <input type="password" name="newPassword" placeholder="新しいパスワード" required><br/>
      <button type="submit">検証</button>
    </form>
    <a href="/signin">ログイン画面</a>
  `);
});

/**
 * パスワードリセット検証API
 */
app.post("/confirm_forgot_password", async (req, res) => {
  // リクエストボディチェック
  const body = req.body;
  if (!body.email)
    return res.status(400).json({ Result: false, Error: "NO_EMAIL" });
  if (!body.confirmationCode)
    return res
      .status(400)
      .json({ Result: false, Error: "NO_CONFIRMATION_CODE" });
  if (!body.newPassword)
    return res.status(400).json({ Result: false, Error: "NO_NEW_PASSWORD" });
  console.log(body);

  // パスワードリセットの検証
  const result = await cognitoClient.confirmForgotPassword(
    APPLICATION_CLIENT_ID,
    body.email,
    body.confirmationCode,
    body.newPassword
  );
  console.log(result);
  if (!result.res)
    return res.status(400).json({
      error: { name: result.error.name, message: result.error.message },
    });

  // ログインページにリダイレクト
  return res.redirect("/signin");
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
    APPLICATION_CLIENT_ID,
    refreshToken
  );
  console.log(JSON.stringify(result, null, 2));
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

  const isTempPassword = (
    await cognitoClient.isTempPassword(USER_POOL_ID, req.session.username)
  ).res;
  if (isTempPassword) {
    return res.status(302).redirect("/set_new_password");
  }

  // ユーザー属性データの取得
  const userData = await cognitoClient.getUserData(accessToken);
  console.log(JSON.stringify(userData, null, 2));
  if (!userData.res)
    return res.status(400).json({
      error: { name: userData.error.name, message: userData.error.message },
    });
  const userAttributes = {};
  for (const attr of userData.res.UserAttributes) {
    userAttributes[attr.Name] = attr.Value;
  }

  if (userAttributes["email_verified"] !== "true") {
    // Cookieにセッションを設定
    // Cookieの上限容量は4096Byte以内であるため、アクセストークンとリフレッシュトークンのみを格納する
    await cognitoClient.verifyEmail(accessToken);
    return res.status(302).redirect("/confirm_verify_email");
  }

  // ユーザー画面
  return res.send(`
    <h1>ユーザー画面</h1>
    <table><tbody>
      <tr><td>メールアドレス：</td><td>${userAttributes["email"]}</td></tr>
      <tr><td>パスワード設定日：</td><td>${userAttributes["custom:password_set_date"]}</td></tr>
      <tr><td>利用開始日：</td><td>${userAttributes["custom:usage_start_date"]}</td></tr>
      <tr><td>利用終了日：</td><td>${userAttributes["custom:usage_end_date"]}</td></tr>
      <tr><td>リフレッシュトークン：</td><td><input type="text" value="${req.session.refreshToken}" size=50 /></td></tr>
      <tr><td>アクセストークン：</td><td><input type="text" value="${req.session.accessToken}" size=50 /></td></tr>
    </tbody></table>
    <h2>メールアドレス変更</h2>
    <form action="/change_email" method="post">
      <input type="email" name="email" placeholder="user@domain" required><br/>
      <button type="submit">変更</button>
    </form>
    <h2>パスワード変更</h2>
    <form action="/change_password" method="post">
      <input type="password" name="currentPassword" placeholder="現在のパスワード" required><br/>
      <input type="password" name="newPassword" placeholder="新しいパスワード" required><br/>
      <button type="submit">変更</button>
    </form>
    <h2>サインアウト</h2>
    <form action="/signout" method="post">
      <button type="submit">サインアウト</button>
    </form>
    <h2>退会</h2>
      <form action="/delete_user" method="post">
      <button type="submit">退会</button>
    </form>
  `);
});

/**
 * メールアドレス変更
 */
app.post("/change_email", async (req, res) => {
  // eslint-disable-next-line @typescript-eslint/no-unsafe-assignment
  const accessToken = req.session.accessToken || false;
  console.log(accessToken);
  // 未認証時
  if (!accessToken) {
    // サインインページにリダイレクト
    return res.status(401).redirect("/signin");
  }
  // リクエストボディチェック
  const body = req.body;
  if (!body.email)
    return res.status(400).json({ Result: false, Error: "NO_EMAIL" });
  console.log(body);

  // メールアドレス変更
  const result = await cognitoClient.changeEmail(body.email, accessToken);
  console.log(JSON.stringify(result, null, 2));
  if (!result.res)
    return res.status(400).json({
      error: { name: result.error.name, message: result.error.message },
    });

  return res.status(302).redirect("/confirm_verify_email");
});

/**
 * パスワード変更API
 */
app.post("/change_password", updateToken, async (req, res) => {
  // eslint-disable-next-line @typescript-eslint/no-unsafe-assignment
  const accessToken = req.session.accessToken || false;
  console.log(accessToken);
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
app.post("/delete_user", async (req, res) => {
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
app.use((_req: Request, res: Response) => {
  return res.status(404).json({ error: "Not Found" });
});

/**
 * サーバーの起動処理
 */
try {
  app.listen(PORT, () => {
    console.log("server running at port:" + PORT);
  });
} catch (e) {
  if (e instanceof Error) {
    console.error(e.message);
  }
}
