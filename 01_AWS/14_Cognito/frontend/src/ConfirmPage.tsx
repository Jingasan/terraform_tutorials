import React from "react";
import { Link, useNavigate } from "react-router-dom";
import { useForm } from "react-hook-form";
import { Auth } from "aws-amplify";
import { getErrorName, getErrorMessage } from "./ErrorMessage";

/**
 * 検証ページ
 */
export default function ConfirmPage() {
  // ページ移動
  const navigate = useNavigate();
  // 入力フォーム
  const { register, handleSubmit } = useForm();
  // 表示メッセージ
  const [displayMessage, setDisplayMessage] = React.useState<JSX.Element>(
    <div></div>
  );

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
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const handleConfirm = (data: any) => {
    const email = data.email1;
    const confirmationCode = data.confirmationCode;
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
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const handleResendConfirmationCode = (data: any) => {
    const email = data.email2;
    Auth.resendSignUp(email)
      .then((res) => {
        console.debug(res);
        // メッセージを表示
        setDisplayMessage(
          <div style={{ color: "blue" }}>検証コードを再送しました。</div>
        );
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
        登録メールアドレスとメールアドレスに届いた検証コードを入力し、検証ボタンを押下してください。
      </div>
      <form onSubmit={handleSubmit(handleConfirm)}>
        <input
          type="email"
          placeholder="email@domain"
          size={50}
          required
          {...register("email1")}
        />
        <br />
        <input
          type="text"
          placeholder="Confirmation Code"
          size={50}
          required
          {...register("confirmationCode")}
        />
        <br />
        <button type="submit">検証</button>
      </form>
      <br />
      <div>
        検証コードを再送する場合は、登録メールアドレスを入力し、再送ボタンを押下してください。
      </div>
      <form onSubmit={handleSubmit(handleResendConfirmationCode)}>
        <input
          type="email"
          placeholder="email@domain"
          size={50}
          required
          {...register("email2")}
        />
        <br />
        <button type="submit">再送</button>
      </form>
      <br />
      <Link to="/">ログイン</Link>
      <br />
      <br />
      {displayMessage}
    </div>
  );
}
