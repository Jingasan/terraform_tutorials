import React from "react";
import { Auth } from "aws-amplify";
import { CognitoUser } from "amazon-cognito-identity-js";

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
              <div style={{ color: "red" }}>{String(err)}</div>
            );
            console.error(err);
          });
      })
      .catch((err) => {
        // エラーメッセージの表示
        setDisplayMessage(<div style={{ color: "red" }}>{String(err)}</div>);
        console.error(err);
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
        setDisplayMessage(<div style={{ color: "red" }}>{String(err)}</div>);
        console.error(err);
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
        setDisplayMessage(<div style={{ color: "red" }}>{String(err)}</div>);
        console.error(err);
      });
  };

  return (
    <div style={{ margin: "30px" }} className="App">
      <h1>ユーザーページ</h1>
      <table>
        <tbody>
          <tr>
            <td>ログインユーザー名：</td>
            <td>{loginUser.getUsername()}</td>
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
      <div>
        <input
          type="password"
          placeholder="Current Password"
          value={currentPassword}
          onChange={(e: React.ChangeEvent<HTMLInputElement>) =>
            setCurrentPassword(e.target.value)
          }
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
