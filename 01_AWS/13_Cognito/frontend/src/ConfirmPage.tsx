import React from "react";
import { Link } from "react-router-dom";
import { Auth } from "aws-amplify";
import { useNavigate } from "react-router-dom";

/**
 * 検証ページ
 */
export default function ConfirmPage() {
  // 表示メッセージ
  const [displayMessage, setDisplayMessage] = React.useState<JSX.Element>(
    <div></div>
  );
  // ユーザー名／パスワード
  const [username, setUsername] = React.useState("");
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
    Auth.confirmSignUp(username, confirmationCode)
      .then((res) => {
        console.debug(res);
        // 表示メッセージを削除
        setDisplayMessage(<div></div>);
        // ログインページへ移動
        navigate("/");
      })
      .catch((err) => {
        // エラーメッセージの表示
        setDisplayMessage(<div style={{ color: "red" }}>{String(err)}</div>);
        console.error(err);
      });
  };

  /**
   * 検証コードの再送
   */
  const handleResendConfirmationCode = () => {
    Auth.resendSignUp(username)
      .then((res) => {
        console.debug(res);
        // 表示メッセージを削除
        setDisplayMessage(<div></div>);
      })
      .catch((err) => {
        // エラーメッセージの表示
        setDisplayMessage(<div style={{ color: "red" }}>{String(err)}</div>);
        console.error(err);
      });
  };

  return (
    <div style={{ margin: "30px" }} className="App">
      <h1>検証</h1>
      <div>
        ユーザー名と届いたメールに記載の検証コードを入力し、Confirmボタンを押下してください。
      </div>
      <div>
        <input
          type="text"
          placeholder="Username"
          value={username}
          onChange={(e: React.ChangeEvent<HTMLInputElement>) =>
            setUsername(e.target.value)
          }
          size={50}
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
        />
      </div>
      <div>
        <button onClick={handleConfirm}>Confirm</button>
      </div>
      <br />
      <div>検証コードを再送する場合は以下のボタンを押下してください。</div>
      <div>
        <input
          type="text"
          placeholder="Username"
          value={username}
          onChange={(e: React.ChangeEvent<HTMLInputElement>) =>
            setUsername(e.target.value)
          }
          size={50}
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
