import * as Cognito from "@aws-sdk/client-cognito-identity-provider";
import express, { Request, Response, NextFunction } from "express";
import session from "express-session";
import cors from "cors";
import * as dotenv from "dotenv";
import { randomUUID } from "crypto";
import { CognitoClient } from "./cognite.mjs";
dotenv.config();
const app = express();
const PORT = 3000;
// Cognitoクライアント
const cognitoClient = new CognitoClient();
// ユーザープールID
const userPoolId = String(process.env.USER_POOL_ID);
// アプリケーションクライアントID
const applicationClientId = String(process.env.APPLICATION_CLIENT_ID);
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
app.get("/administrator", async (_req, res) => {
  res.send(`
    <h1>管理者画面</h1>
    <h2>新規ユーザー登録</h2>
    <form action="/create_user" method="post">
      <input type="email" name="email" placeholder="email@domain" required><br/>
      <input type="text" name="family_name" placeholder="姓" required>
      <input type="text" name="given_name" placeholder="名" required><br/>
      <input type="text" name="family_name_kana" placeholder="姓(カナ)" required>
      <input type="text" name="given_name_kana" placeholder="名(カナ)" required><br/>
      <input type="text" name="birthdate" placeholder="生年月日" required><br/>
      <input type="text" name="address" placeholder="住所" required><br/>
      <input type="tel" name="tel" placeholder="電話番号" required><br/>
      <input type="text" name="request_class" placeholder="申請区分" required><br/>
      <textarea name="purpose" cols="100" rows="5" placeholder="利用目的"></textarea><br/>
      <button type="submit">新規登録</button>
    </form>
    <h2>ユーザー削除</h2>
    <form action="/delete_user" method="post">
      <input type="email" name="email" placeholder="email@domain" required><br/>
      <button type="submit">ユーザー削除</button>
    </form>
    <a href="/signin">ログイン</a>
  `);
});

/**
 * 新規ユーザー作成
 */
app.post("/create_user", async (req, res) => {
  // リクエストボディチェック
  const body = req.body;
  if (!body.email)
    return res.status(400).json({ Result: false, Error: "NO_EMAIL" });
  if (!body.family_name)
    return res.status(400).json({ Result: false, Error: "NO_FAMILY_NAME" });
  if (!body.given_name)
    return res.status(400).json({ Result: false, Error: "NO_GIVEN_NAME" });
  if (!body.tel)
    return res.status(400).json({ Result: false, Error: "NO_TEL" });
  console.log(body);

  // 新規ユーザー作成
  const result = await cognitoClient.adminCreateUser(
    userPoolId,
    body.email,
    body.email,
    body.family_name,
    body.given_name,
    body.family_name_kana,
    body.given_name_kana,
    body.birthdate,
    body.address,
    body.tel,
    body.request_class,
    body.purpose
  );
  console.log(JSON.stringify(result, null, "  "));
  if (!result.res)
    return res.status(400).json({
      error: { name: result.error.name, message: result.error.message },
    });

  return res.status(302).redirect("/signin");
});

/**
 * ユーザー削除
 */
app.post("/delete_user", async (req, res) => {
  // リクエストボディチェック
  const body = req.body;
  if (!body.email)
    return res.status(400).json({ Result: false, Error: "NO_USERNAME" });
  console.log(body);

  // ユーザー削除
  const result = await cognitoClient.adminDeleteUser(userPoolId, body.email);
  console.log(JSON.stringify(result, null, "  "));
  if (!result.res)
    return res.status(400).json({
      error: { name: result.error.name, message: result.error.message },
    });

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
    <a href="/forgot_password">パスワードを忘れた場合</a><br/>
    <a href="/administrator">管理者画面</a><br/>
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

  if (result.res.ChallengeName === "EMAIL_OTP") {
    req.session.cognitoSession = result.res.Session;
    req.session.username = body.email;
    req.session.challengeName = result.res.ChallengeName;
    return res.status(302).redirect("/response_to_auth_challenge");
  } else if (result.res.ChallengeName === "NEW_PASSWORD_REQUIRED") {
    req.session.cognitoSession = result.res.Session;
    req.session.username = body.email;
    req.session.challengeName = result.res.ChallengeName;
    return res.status(302).redirect("/set_new_password");
  }

  // Cookieにセッションを設定
  // Cookieの上限容量は4096Byte以内であるため、アクセストークンとリフレッシュトークンのみを格納する
  req.session.accessToken = result.res.AuthenticationResult.AccessToken;
  req.session.refreshToken = result.res.AuthenticationResult.RefreshToken;

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
    <a href="/signin">ログイン</a>
  `);
});

/**
 * パスワード変更ページ
 */
app.get("/set_new_password", async (_req, res) => {
  res.send(`
    <h1>初回パスワード設定画面</h1>
    <form action="/response_to_auth_challenge" method="post">
      <input type="password" name="code" placeholder="新しいパスワード" required><br/>
      <button type="submit">変更</button>
    </form>
    <a href="/signin">ログイン</a>
  `);
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
    applicationClientId,
    challengeName,
    username,
    body.code,
    cognitoSession
  );
  console.log(JSON.stringify(result, null, "  "));
  if (!result.res)
    return res.status(400).json({
      error: { name: result.error.name, message: result.error.message },
    });

  if (
    result.res.ChallengeName === "EMAIL_OTP" ||
    result.res.ChallengeName === "SMS_MFA"
  ) {
    req.session.cognitoSession = result.res.Session;
    req.session.username = username;
    req.session.challengeName = result.res.ChallengeName;
    return res.status(302).redirect("/response_to_auth_challenge");
  }

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
    <a href="/signin">ログイン</a>
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
    <a href="/signin">ログイン</a>
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
    applicationClientId,
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
    <a href="/signin">ログイン</a>
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
    applicationClientId,
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

  if (userAttributes["email_verified"] === "false") {
    // Cookieにセッションを設定
    // Cookieの上限容量は4096Byte以内であるため、アクセストークンとリフレッシュトークンのみを格納する
    await cognitoClient.verifyEmail(accessToken);
    return res.status(302).redirect("/confirm_verify_email");
  }

  // ユーザー画面
  return res.send(`
    <h1>ユーザー画面</h1>
    <table><tbody>
      <tr><td>姓名：</td><td>${userAttributes["family_name"]} ${userAttributes["given_name"]}</td></tr>
      <tr><td>姓名（カナ）：</td><td>${userAttributes["custom:family_name_kana"]} ${userAttributes["custom:given_name_kana"]}</td></tr>
      <tr><td>生年月日：</td><td>${userAttributes["birthdate"]}</td></tr>
      <tr><td>住所：</td><td>${userAttributes["address"]}</td></tr>
      <tr><td>メールアドレス：</td><td>${userAttributes["email"]}</td></tr>
      <tr><td>電話番号：</td><td>${userAttributes["custom:tel"]}</td></tr>
      <tr><td>申請区分：</td><td>${userAttributes["custom:request_class"]}</td></tr>
      <tr><td>利用目的：</td><td>${userAttributes["custom:purpose"]}</td></tr>
      <tr><td>リフレッシュトークン：</td><td><input type="text" value="${req.session.refreshToken}" size=50 /></td></tr>
      <tr><td>アクセストークン：</td><td><input type="text" value="${req.session.accessToken}" size=50 /></td></tr>
    </tbody></table>
    <h2>パスワード変更</h2>
    <form action="/change_password" method="post">
      <input type="text" name="currentPassword" placeholder="現在のパスワード" required><br/>
      <input type="text" name="newPassword" placeholder="新しいパスワード" required><br/>
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
