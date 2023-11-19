import React from "react";
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
  // 表示メッセージ
  const [displayMessage, setDisplayMessage] = React.useState<JSX.Element>(
    <div></div>
  );
  // 現在のパスワード／新しいパスワード
  const [currentPassword, setCurrentPassword] = React.useState("");
  const [newPassword, setNewPassword] = React.useState("");
  const [name, setName] = React.useState("");
  const [email, setEmail] = React.useState("");

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
  const handleChangePassword = () => {
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
                required
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
                required
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
                required
              />
            </td>
          </tr>
        </tbody>
      </table>
      <br />
      <div>パスワード変更</div>
      <div>
        <input
          type="password"
          placeholder="Current Password"
          value={currentPassword}
          onChange={(e: React.ChangeEvent<HTMLInputElement>) =>
            setCurrentPassword(e.target.value)
          }
          size={50}
          required
        />
      </div>
      <div>
        <input
          type="password"
          placeholder="New Password"
          value={newPassword}
          onChange={(e: React.ChangeEvent<HTMLInputElement>) =>
            setNewPassword(e.target.value)
          }
          size={50}
          required
        />
      </div>
      <div>
        <button onClick={handleChangePassword}>Change</button>
      </div>
      <br />
      <div>ログアウトする場合は、Logoutボタンを押下してください。</div>
      <div>
        <button onClick={handleLogout}>Logout</button>
      </div>
      <br />
      <div>退会する場合は、DeleteUserボタンを押下してください。</div>
      <div>
        <button onClick={handleDeleteUser}>DeleteUser</button>
      </div>
      <br />
      <br />
      {displayMessage}
    </div>
  );
}
