import React from "react";
import { Link, useNavigate } from "react-router-dom";
import { useForm } from "react-hook-form";
import { Auth } from "aws-amplify";
import { getErrorName, getErrorMessage } from "./ErrorMessage";

/**
 * パスワードリセットページ
 */
export default function PasswordResetPage() {
  // 入力フォーム
  const { register, handleSubmit } = useForm();
  // ページ移動
  const navigate = useNavigate();
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
   * パスワードリセットのための検証コードの要求
   */
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const handleRequestConfirmationCode = (data: any) => {
    const email = data.email1;
    Auth.forgotPassword(email)
      .then((res) => {
        console.debug(res);
        // メッセージを表示
        setDisplayMessage(
          <div style={{ color: "blue" }}>検証コードを送信しました。</div>
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

  /**
   * パスワードリセット
   */
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const handleResetPassword = (data: any) => {
    const email = data.email2;
    const confirmationCode = data.confirmationCode;
    const password = data.password;
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
        １．登録メールアドレスを入力し、送信ボタンを押下してください。検証コードが記載されたメールが届きます。
      </div>
      <form onSubmit={handleSubmit(handleRequestConfirmationCode)}>
        <input
          type="email"
          placeholder="email@domain"
          size={50}
          required
          {...register("email1")}
        />
        <br />
        <button type="submit">送信</button>
      </form>
      <br />
      <br />
      <div>
        ２．登録メールアドレス／検証コード／新しいパスワードを入力し、リセットボタンを押下してください。
      </div>
      <form onSubmit={handleSubmit(handleResetPassword)}>
        <input
          type="email"
          placeholder="email@domain"
          size={50}
          required
          {...register("email2")}
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
        <input
          type="text"
          placeholder="Password"
          size={50}
          required
          {...register("password")}
        />
        <br />
        <button type="submit">リセット</button>
      </form>
      <br />
      <Link to="/">ログイン</Link>
      <br />
      <br />
      {displayMessage}
    </div>
  );
}
