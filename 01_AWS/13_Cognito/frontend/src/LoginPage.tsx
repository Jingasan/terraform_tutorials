import React from "react";
import { Link } from "react-router-dom";
import { Auth } from "aws-amplify";
import { CognitoUser } from "amazon-cognito-identity-js";

/**
 * ログインページ
 */
export interface Props {
  setLoginUser: (loginUser: CognitoUser | undefined) => void;
}
export default function LoginPage(props: Props) {
  const { setLoginUser } = props;
  // 表示メッセージ
  const [displayMessage, setDisplayMessage] = React.useState<JSX.Element>(
    <div></div>
  );
  // ユーザー名／パスワード
  const [username, setUsername] = React.useState("");
  const [password, setPassword] = React.useState("");

  /**
   * 画面の初期化
   */
  React.useEffect(() => {
    // 表示メッセージを削除
    setDisplayMessage(<div></div>);
    // アンマウント時の処理
    return () => {};
  }, []);

  /**
   * ログイン処理
   */
  const handleLogin = () => {
    Auth.signIn(username, password)
      .then((user) => {
        // 表示メッセージを削除
        setDisplayMessage(<div></div>);
        // 現在のログインユーザーを更新
        setLoginUser(user);
        console.debug(user);
      })
      .catch((err) => {
        // エラーメッセージの表示
        setDisplayMessage(<div style={{ color: "red" }}>{String(err)}</div>);
        // 現在のログインユーザーを更新
        setLoginUser(undefined);
        console.error(err);
      });
  };

  return (
    <div style={{ margin: "30px" }} className="App">
      <h1>ログイン画面</h1>
      <div>ユーザー名／パスワードを入力し、Loginボタンを押下してください。</div>
      <div>
        <input
          type="text"
          placeholder="Username"
          value={username}
          onChange={(e) => setUsername(e.target.value)}
        />
      </div>
      <div>
        <input
          type="password"
          placeholder="Password"
          value={password}
          onChange={(e) => setPassword(e.target.value)}
        />
      </div>
      <div>
        <button onClick={handleLogin}>Login</button>
      </div>
      <br />
      <Link to="/Signup">新規登録</Link>
      <br />
      <Link to="/PasswordReset">パスワードを忘れた場合</Link>
      <br />
      <br />
      {displayMessage}
    </div>
  );
}
