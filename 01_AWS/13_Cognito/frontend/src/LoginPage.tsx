import React from "react";
import { Link } from "react-router-dom";
import { useForm } from "react-hook-form";
import { Auth } from "aws-amplify";
import { CognitoUser } from "amazon-cognito-identity-js";
import { getErrorName, getErrorMessage } from "./ErrorMessage";

/**
 * ログインページ
 */
export interface Props {
  setLoginUser: (loginUser: CognitoUser | undefined) => void;
}
export default function LoginPage(props: Props) {
  const { setLoginUser } = props;
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
   * ログイン処理
   */
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const handleLogin = (data: any) => {
    const email = data.email;
    const password = data.password;
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

  return (
    <div style={{ margin: "30px" }} className="App">
      <h1>ログイン画面</h1>
      <div>
        登録メールアドレス／パスワードを入力し、ログインボタンを押下してください。
      </div>
      <form onSubmit={handleSubmit(handleLogin)}>
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
        <button type="submit">ログイン</button>
      </form>
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
