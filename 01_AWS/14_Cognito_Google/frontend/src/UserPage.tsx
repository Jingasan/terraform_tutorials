import React from "react";
import { useForm } from "react-hook-form";
import { Auth } from "aws-amplify";
import { CognitoUser } from "amazon-cognito-identity-js";
import { getErrorName, getErrorMessage } from "./ErrorMessage";

/**
 * ユーザーページ
 */
export interface Props {
  loginUser: CognitoUser;
  setLoginUser: (loginUser: CognitoUser | undefined) => void;
}
export default function UserPage(props: Props) {
  const { loginUser, setLoginUser } = props;
  // ユーザー名とメールアドレス
  const [name, setName] = React.useState("");
  const [email, setEmail] = React.useState("");
  // 入力フォーム
  const { register, handleSubmit } = useForm();
  // 表示メッセージ
  const [displayMessage, setDisplayMessage] = React.useState<JSX.Element>(
    <div></div>
  );

  /**
   * ユーザー情報の取得
   */
  React.useEffect(() => {
    loginUser.getUserAttributes((err, attributes) => {
      if (err) return;
      attributes?.forEach((attr) => {
        if (attr.getName() === "name") setName(attr.getValue());
        if (attr.getName() === "email") setEmail(attr.getValue());
      });
    });
  }, [loginUser]);

  /**
   * パスワードの変更
   */
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const handleChangePassword = (data: any) => {
    const currentPassword = data.currentPassword;
    const newPassword = data.newPassword;
    Auth.currentAuthenticatedUser()
      .then((user) => {
        Auth.changePassword(user, currentPassword, newPassword)
          .then(() => {
            // パスワード変更完了のメッセージを表示
            setDisplayMessage(
              <div style={{ color: "blue" }}>パスワード変更完了</div>
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
   * ログアウト処理
   */
  const handleLogout = () => {
    Auth.signOut()
      .then(() => {
        // 表示メッセージを削除
        setDisplayMessage(<div></div>);
        // 現在のログインユーザーを更新
        setLoginUser(undefined);
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
   * ユーザー削除処理
   */
  const handleDeleteUser = () => {
    Auth.deleteUser()
      .then(() => {
        // 表示メッセージを削除
        setDisplayMessage(<div></div>);
        // 現在のログインユーザーを更新
        setLoginUser(undefined);
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
      <h1>ユーザー画面</h1>
      <table>
        <tbody>
          <tr>
            <td>ログインユーザー名：</td>
            <td>{name}</td>
          </tr>
          <tr>
            <td>メールアドレス：</td>
            <td>{email}</td>
          </tr>
          <tr>
            <td>IDトークン：</td>
            <td>
              <input
                type="text"
                defaultValue={String(
                  loginUser.getSignInUserSession()?.getIdToken().getJwtToken()
                )}
                size={50}
              />
            </td>
          </tr>
          <tr>
            <td>アクセストークン：</td>
            <td>
              <input
                type="text"
                defaultValue={String(
                  loginUser
                    .getSignInUserSession()
                    ?.getAccessToken()
                    .getJwtToken()
                )}
                size={50}
              />
            </td>
          </tr>
          <tr>
            <td>リフレッシュトークン：</td>
            <td>
              <input
                type="text"
                defaultValue={String(
                  loginUser.getSignInUserSession()?.getRefreshToken().getToken()
                )}
                size={50}
              />
            </td>
          </tr>
        </tbody>
      </table>
      <br />
      <div>パスワード変更</div>
      <form onSubmit={handleSubmit(handleChangePassword)}>
        <input
          type="text"
          placeholder="Current Password"
          size={50}
          required
          {...register("currentPassword")}
        />
        <br />
        <input
          type="text"
          placeholder="New Password"
          size={50}
          required
          {...register("newPassword")}
        />
        <br />
        <button type="submit">変更</button>
      </form>
      <br />
      <div>ログアウトする場合は、ログアウトボタンを押下してください。</div>
      <div>
        <button onClick={handleLogout}>ログアウト</button>
      </div>
      <br />
      <div>退会する場合は、退会ボタンを押下してください。</div>
      <div>
        <button onClick={handleDeleteUser}>退会</button>
      </div>
      <br />
      <br />
      {displayMessage}
    </div>
  );
}
