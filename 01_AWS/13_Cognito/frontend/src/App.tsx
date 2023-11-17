import React from "react";
import { BrowserRouter, Route, Routes, Navigate } from "react-router-dom";
import LoginPage from "./LoginPage";
import UserPage from "./UserPage";
import SignupPage from "./SignupPage";
import ConfirmPage from "./ConfirmPage";
import PasswordResetPage from "./PasswordResetPage";
import { Amplify, Auth } from "aws-amplify";
import { CognitoUser } from "amazon-cognito-identity-js";
import config from "./config.json";

/**
 * Cognito
 */
Amplify.configure(config);

/**
 * ルート
 */
export default function App() {
  // ログインユーザー情報
  const [loginUser, setLoginUser] = React.useState<CognitoUser | undefined>(
    undefined
  );

  /**
   * 画面の初期化
   */
  React.useEffect(() => {
    // ログイン状態チェックとリフレッシュトークンを更新
    Auth.currentAuthenticatedUser()
      .then((user: CognitoUser) => {
        // 現在のログインユーザーを更新
        setLoginUser(user);
        console.debug(user);
      })
      .catch((err) => {
        // 現在のログインユーザーを更新
        setLoginUser(undefined);
        console.debug(err);
      });
    // アンマウント時の処理
    return () => {};
  }, []);

  return (
    <BrowserRouter>
      <Routes>
        {/* ユーザーページ／ログインページ */}
        <Route
          path="/index.html"
          element={<Navigate to="/" replace={true} />}
        />
        <Route
          path="/"
          element={
            loginUser ? (
              <UserPage loginUser={loginUser} setLoginUser={setLoginUser} />
            ) : (
              <LoginPage setLoginUser={setLoginUser} />
            )
          }
        />
        {/* サインアップページ */}
        <Route path="/Signup" element={<SignupPage />} />
        {/* 検証ページ */}
        <Route path="/Confirm" element={<ConfirmPage />} />
        {/* パスワードリセットページ */}
        <Route path="/PasswordReset" element={<PasswordResetPage />} />
      </Routes>
    </BrowserRouter>
  );
}
