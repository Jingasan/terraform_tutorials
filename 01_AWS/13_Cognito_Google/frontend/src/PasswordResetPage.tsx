import React from "react";
import { Link } from "react-router-dom";
import { Auth } from "aws-amplify";
import { useNavigate } from "react-router-dom";
import { getErrorName, getErrorMessage } from "./ErrorMessage";

/**
 * パスワードリセットページ
 */
export default function PasswordResetPage() {
  // 表示メッセージ
  const [displayMessage, setDisplayMessage] = React.useState<JSX.Element>(
    <div></div>
  );
  // メールアドレス／パスワード／検証コード
  const [email, setEmail] = React.useState("");
  const [password, setPassword] = React.useState("");
  const [confirmationCode, setConfirmationCode] = React.useState("");
  // ページ移動
  const navigate = useNavigate();

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
   * パスワードリセットのための検証コードの要求
   */
  const handleRequestConfirmationCode = () => {
    Auth.forgotPassword(email)
      .then((res) => {
        console.debug(res);
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
      });
  };

  /**
   * パスワードリセット
   */
  const handleResetPassword = () => {
    Auth.forgotPasswordSubmit(email, confirmationCode, password)
      .then((res) => {
        // 表示メッセージを削除
        setDisplayMessage(<div></div>);
        console.debug(res);
        // ログインページへ移動
        navigate("/");
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
      });
  };

  return (
    <div style={{ margin: "30px" }} className="App">
      <h1>パスワード再設定画面</h1>
      <div>
        １．登録メールアドレスを入力し、Requestボタンを押下してください。検証コードが記載されたメールが届きます。
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
        <button onClick={handleRequestConfirmationCode}>Request</button>
      </div>
      <br />
      <br />
      <div>
        ２．登録メールアドレス／検証コード／新しいパスワードを入力し、Resetボタンを押下してください。
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
          type="text"
          placeholder="ConfirmationCode"
          value={confirmationCode}
          onChange={(e: React.ChangeEvent<HTMLInputElement>) =>
            setConfirmationCode(e.target.value)
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
        <button onClick={handleResetPassword}>Reset</button>
      </div>
      <br />
      <Link to="/">ログイン</Link>
      <br />
      <br />
      {displayMessage}
    </div>
  );
}
