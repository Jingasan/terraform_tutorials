/**
 * 日本語エラー名の取得
 * @param name エラー名
 * @returns 日本語エラー名
 */
export const getErrorName = (name: string): string => {
  switch (name) {
    // Cognito系エラー
    case "UsernameExistsException":
      return "ユーザー名存在エラー";
    case "InvalidPasswordException":
      return "パスワードエラー";
    case "CodeMismatchException":
      return "検証コード不一致エラー";
    case "ExpiredCodeException":
      return "検証コード期限切れエラー";
    case "InvalidParameterException":
      return "パラメータエラー";
    case "LimitExceededException":
      return "試行回数エラー";
    case "UserNotFoundException":
      return "ユーザー名不在エラー";
    case "NotAuthorizedException":
      return "認証エラー";
    case "AuthError":
      return "認証エラー";
    // それ以外
    default:
      return "エラー";
  }
};

/**
 * 日本語エラーメッセージの取得
 * @param message エラーメッセージ
 * @returns 日本語エラーメッセージ
 */
export const getErrorMessage = (message: string): string | undefined => {
  switch (message) {
    // Signup系
    case "Username cannot be empty":
      return "メールアドレスは空にできません。";
    case "User account already exists":
      return "ユーザー名がすでに存在しています。";
    case "An account with the email already exists.":
      return "メールアドレスがすでに存在しています。";
    case "Password cannot be empty":
      return "パスワードは空にできません。";
    case "Invalid email address format.":
      return "メールアドレスが不正な形式です。";
    case "Password did not conform with policy: Password not long enough":
      return "パスワードの文字数が不十分です。";
    case "Password did not conform with password policy: Password must have uppercase characters":
      return "パスワードには大文字を含める必要があります。";
    case "Password did not conform with password policy: Password must have lowercase characters":
      return "パスワードには小文字を含める必要があります。";
    case "Password did not conform with password policy: Password must have numeric characters":
      return "パスワードには数字を含める必要があります。";
    // Confirm系
    case "Invalid session provided":
      return "検証コードが不正です。";
    case "Invalid code provided, please request a code again.":
      return "検証コードが期限切れです。検証コードを再度発行してください。";
    // Signin系
    case "User does not exist.":
      return "メールアドレスが存在しません。";
    case "Attempt limit exceeded, please try after some time.":
      return "試行回数が上限に達しました。暫くしてから試してください。";
    case "Incorrect username or password.":
      return "ユーザー名またはパスワードが不正です。";
    case "Invalid Access Token":
      return "不正なアクセストークンです。";
    case "Invalid Refresh Token":
      return "不正なリフレッシュトークンです。";
    // それ以外
    default:
      return undefined;
  }
};
