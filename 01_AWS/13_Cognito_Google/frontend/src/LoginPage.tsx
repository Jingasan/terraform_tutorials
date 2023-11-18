import React from "react";
import { Link } from "react-router-dom";
import { Auth } from "aws-amplify";
import { CognitoUser } from "amazon-cognito-identity-js";
import { CognitoHostedUIIdentityProvider } from "@aws-amplify/auth";
import { getErrorName, getErrorMessage } from "./ErrorMessage";

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
  // メールアドレス／パスワード
  const [email, setEmail] = React.useState("");
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
    Auth.signIn(email, password)
      .then((user) => {
        // 表示メッセージを削除
        setDisplayMessage(<div></div>);
        // 現在のログインユーザーを更新
        setLoginUser(user);
        console.debug(user);
      })
      .catch((err) => {
        // エラーメッセージの表示
        setDisplayMessage(
          <div style={{ color: "red" }}>
            {getErrorName(err.name)}
            <br />
            {getErrorMessage(err.message) ?? err.message}
          </div>
        );
        console.error(err.name);
        console.error(err.message);
        // 現在のログインユーザーを更新
        setLoginUser(undefined);
      });
  };

  /**
   * Googleアカウントによるログイン
   */
  const handleLoginGoogle = () => {
    Auth.federatedSignIn({ provider: CognitoHostedUIIdentityProvider.Google })
      .then(() => {
        // 表示メッセージを削除
        setDisplayMessage(<div></div>);
      })
      .catch((err) => {
        // エラーメッセージの表示
        setDisplayMessage(
          <div style={{ color: "red" }}>
            {getErrorName(err.name)}
            <br />
            {getErrorMessage(err.message) ?? err.message}
          </div>
        );
        console.error(err.name);
        console.error(err.message);
        // 現在のログインユーザーを更新
        setLoginUser(undefined);
      });
  };

  return (
    <div style={{ margin: "30px" }} className="App">
      <h1>ログイン画面</h1>
      <div>
        登録メールアドレス／パスワードを入力し、Loginボタンを押下してください。
      </div>
      <div>
        <input
          type="email"
          placeholder="email@domain"
          value={email}
          onChange={(e: React.ChangeEvent<HTMLInputElement>) =>
            setEmail(e.target.value)
          }
          size={50}
        />
      </div>
      <div>
        <input
          type="password"
          placeholder="Password"
          value={password}
          onChange={(e: React.ChangeEvent<HTMLInputElement>) =>
            setPassword(e.target.value)
          }
          size={50}
        />
      </div>
      <div>
        <button onClick={handleLogin}>Login</button>
      </div>
      <br />
      <div>Googleアカウントによるログイン</div>
      <div>
        <button onClick={handleLoginGoogle}>Login</button>
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
