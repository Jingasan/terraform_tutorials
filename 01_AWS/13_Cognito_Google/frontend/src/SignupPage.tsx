import React from "react";
import { Link } from "react-router-dom";
import { Auth } from "aws-amplify";
import { useNavigate } from "react-router-dom";
import { getErrorName, getErrorMessage } from "./ErrorMessage";

/**
 * サインアップページ
 */
export default function SignupPage() {
  // 表示メッセージ
  const [displayMessage, setDisplayMessage] = React.useState<JSX.Element>(
    <div></div>
  );
  // ユーザー名／メールアドレス／パスワード
  const [username, setUsername] = React.useState("");
  const [email, setEmail] = React.useState("");
  const [password, setPassword] = React.useState("");
  // ページ移動
  const navigate = useNavigate();

  /**
   * 画面の初期化：ログイン状態をチェック
   */
  React.useEffect(() => {
    // 表示メッセージを非表示にする
    setDisplayMessage(<div></div>);
    // アンマウント時の処理
    return () => {};
  }, []);

  /**
   * サインアップ処理
   */
  const handleSignup = () => {
    Auth.signUp({
      username: email,
      password: password,
      attributes: {
        preferred_username: username,
        name: username,
        email: email,
      },
    })
      .then((res) => {
        // 表示メッセージを非表示にする
        setDisplayMessage(<div></div>);
        // 検証コード入力ページへ移動
        navigate("/Confirm");
        console.debug(res);
      })
      .catch((err: Error) => {
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
      });
  };

  return (
    <div style={{ margin: "30px" }} className="App">
      <h1>サインアップ画面</h1>
      <div>
        ユーザー名／メールアドレス／パスワードを入力し、Signupボタンを押下してください。
      </div>
      <div>入力したメールアドレス宛てに検証コードが届きます。</div>
      <div>
        <input
          type="text"
          placeholder="Username"
          value={username}
          onChange={(e: React.ChangeEvent<HTMLInputElement>) =>
            setUsername(e.target.value)
          }
          size={50}
          required
        />
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
          required
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
          required
        />
      </div>
      <div>
        <button onClick={handleSignup}>Signup</button>
      </div>
      <br />
      <Link to="/">ログイン</Link>
      <br />
      <br />
      {displayMessage}
    </div>
  );
}
