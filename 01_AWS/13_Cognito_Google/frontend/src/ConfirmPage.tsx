import React from "react";
import { Link } from "react-router-dom";
import { Auth } from "aws-amplify";
import { useNavigate } from "react-router-dom";
import { getErrorName, getErrorMessage } from "./ErrorMessage";

/**
 * 検証ページ
 */
export default function ConfirmPage() {
  // 表示メッセージ
  const [displayMessage, setDisplayMessage] = React.useState<JSX.Element>(
    <div></div>
  );
  // メールアドレス／パスワード
  const [email, setEmail] = React.useState("");
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
   * 検証
   */
  const handleConfirm = () => {
    Auth.confirmSignUp(email, confirmationCode)
      .then((res) => {
        console.debug(res);
        // 表示メッセージを削除
        setDisplayMessage(<div></div>);
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

  /**
   * 検証コードの再送
   */
  const handleResendConfirmationCode = () => {
    Auth.resendSignUp(email)
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

  return (
    <div style={{ margin: "30px" }} className="App">
      <h1>検証画面</h1>
      <div>
        登録メールアドレスとメールアドレスに届いた検証コードを入力し、Confirmボタンを押下してください。
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
          type="text"
          placeholder="Confirmation Code"
          value={confirmationCode}
          onChange={(e: React.ChangeEvent<HTMLInputElement>) =>
            setConfirmationCode(e.target.value)
          }
          size={50}
          required
        />
      </div>
      <div>
        <button onClick={handleConfirm}>Confirm</button>
      </div>
      <br />
      <div>検証コードを再送する場合は以下のボタンを押下してください。</div>
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
        <button onClick={handleResendConfirmationCode}>Resend</button>
      </div>
      <br />
      <Link to="/">ログイン</Link>
      <br />
      <br />
      {displayMessage}
    </div>
  );
}
