import React from "react";
import { Link, useNavigate } from "react-router-dom";
import { useForm } from "react-hook-form";
import { Auth } from "aws-amplify";
import { getErrorName, getErrorMessage } from "./ErrorMessage";

/**
 * サインアップページ
 */
export default function SignupPage() {
  // ページ移動
  const navigate = useNavigate();
  // 入力フォーム
  const { register, handleSubmit } = useForm();
  // 表示メッセージ
  const [displayMessage, setDisplayMessage] = React.useState<JSX.Element>(
    <div></div>
  );

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
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const handleSignup = (data: any) => {
    const username = data.username;
    const email = data.email;
    const password = data.password;
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
        ユーザー名／メールアドレス／パスワードを入力し、新規登録ボタンを押下してください。
      </div>
      <div>入力したメールアドレス宛てに検証コードが届きます。</div>
      <form onSubmit={handleSubmit(handleSignup)}>
        <input
          type="text"
          placeholder="Username"
          size={50}
          required
          {...register("username")}
        />
        <br />
        <input
          type="email"
          placeholder="email@domain"
          size={50}
          required
          {...register("email")}
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
        <button type="submit">新規登録</button>
      </form>
      <br />
      <Link to="/">ログイン</Link>
      <br />
      <br />
      {displayMessage}
    </div>
  );
}
