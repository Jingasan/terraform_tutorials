import * as Cognito from "@aws-sdk/client-cognito-identity-provider";

/**
 * Cognitoクライアントクラス
 */
export class CognitoClient {
  /**
   * Cognitoクライアント
   */
  private cognitoClient = new Cognito.CognitoIdentityProviderClient({
    region: "ap-northeast-1",
  });
  /**
   * サインアップ（ユーザーによるアカウント作成）
   * @param clientId アプリケーションクライアントID
   * @param username 新規ユーザー名
   * @param email メールアドレス
   * @param password パスワード
   * @returns ユーザー情報/false:サインアップ失敗
   */
  public signUp = async (
    clientId: string,
    username: string,
    email: string,
    name: string,
    password: string
  ): Promise<{
    res: Cognito.SignUpCommandOutput | false;
    error?: Cognito.InternalErrorException;
  }> => {
    try {
      const command = new Cognito.SignUpCommand({
        ClientId: clientId,
        Username: username,
        Password: password,
        UserAttributes: [
          { Name: "email", Value: email },
          { Name: "name", Value: name },
        ],
      });
      const res = await this.cognitoClient.send(command);
      return { res: res };
    } catch (err) {
      console.error((err as Cognito.InternalErrorException).name);
      console.error((err as Cognito.InternalErrorException).message);
      return {
        res: undefined,
        error: err as Cognito.InternalErrorException,
      };
    }
  };
  /**
   * ユーザーによるサインアップ検証(Confirm)
   * @param userPoolClientId アプリケーションクライアントのID
   * @param username ユーザー名
   * @param confirmationCode Confirm Code
   * @returns true:成功/false:失敗
   */
  public confirmSignUp = async (
    userPoolClientId: string,
    username: string,
    confirmationCode: string
  ): Promise<{
    res: boolean;
    error?: Cognito.InternalErrorException;
  }> => {
    try {
      const command = new Cognito.ConfirmSignUpCommand({
        ClientId: userPoolClientId,
        Username: username,
        ConfirmationCode: confirmationCode,
      });
      await this.cognitoClient.send(command);
      return { res: true };
    } catch (err) {
      console.error((err as Cognito.InternalErrorException).name);
      console.error((err as Cognito.InternalErrorException).message);
      return {
        res: false,
        error: err as Cognito.InternalErrorException,
      };
    }
  };
  /**
   * サインイン
   * @param clientId アプリケーションクライアントID
   * @param username ユーザー名
   * @param password パスワード
   * @returns サインイン結果/false:失敗
   */
  public initiateAuth = async (
    clientId: string,
    username: string,
    password: string
  ): Promise<{
    res: Cognito.AdminInitiateAuthCommandOutput | false;
    error?: Cognito.InternalErrorException;
  }> => {
    try {
      const command = new Cognito.InitiateAuthCommand({
        ClientId: clientId,
        // ユーザープールの設定でALLOW_USER_PASSWORD_AUTHの有効化が必要
        AuthFlow: Cognito.AuthFlowType.USER_PASSWORD_AUTH,
        AuthParameters: { USERNAME: username, PASSWORD: password },
      });
      const res = await this.cognitoClient.send(command);
      return { res: res };
    } catch (err) {
      console.error((err as Cognito.InternalErrorException).name);
      console.error((err as Cognito.InternalErrorException).message);
      return {
        res: false,
        error: err as Cognito.InternalErrorException,
      };
    }
  };
  /**
   * トークンの更新
   * @param clientId アプリケーションクライアントID
   * @param refreshToken リフレッシュトークン
   * @returns 更新後のトークン/false:失敗
   */
  public updateToken = async (
    clientId: string,
    refreshToken: string
  ): Promise<{
    res: Cognito.AdminInitiateAuthCommandOutput | false;
    error?: Cognito.InternalErrorException;
  }> => {
    try {
      const command = new Cognito.InitiateAuthCommand({
        ClientId: clientId,
        // ユーザープールの設定でALLOW_REFRESH_TOKEN_AUTHの有効化が必要
        AuthFlow: Cognito.AuthFlowType.REFRESH_TOKEN,
        AuthParameters: { REFRESH_TOKEN: refreshToken },
      });
      const res = await this.cognitoClient.send(command);
      return { res: res };
    } catch (err) {
      console.error((err as Cognito.InternalErrorException).name);
      console.error((err as Cognito.InternalErrorException).message);
      return {
        res: false,
        error: err as Cognito.InternalErrorException,
      };
    }
  };
  /**
   * ユーザー属性データの取得
   * @param accessToken アクセストークン
   * @returns ユーザー属性データ/false:取得失敗
   */
  public getUserData = async (
    accessToken: string
  ): Promise<{
    res: Cognito.GetUserCommandOutput | false;
    error?: Cognito.InternalErrorException;
  }> => {
    try {
      const command = new Cognito.GetUserCommand({
        AccessToken: accessToken,
      });
      const res = await this.cognitoClient.send(command);
      return { res: res };
    } catch (err) {
      console.error((err as Cognito.InternalErrorException).name);
      console.error((err as Cognito.InternalErrorException).message);
      return {
        res: undefined,
        error: err as Cognito.InternalErrorException,
      };
    }
  };
  /**
   * パスワード変更
   * @param previousPassword 現在のパスワード
   * @param proposedPassword 新規パスワード
   * @param accessToken アクセストークン
   * @returns true:成功/false:失敗
   */
  public changePassword = async (
    previousPassword: string,
    proposedPassword: string,
    accessToken: string
  ): Promise<{ res: boolean; error?: Cognito.InternalErrorException }> => {
    try {
      const command = new Cognito.ChangePasswordCommand({
        PreviousPassword: previousPassword,
        ProposedPassword: proposedPassword,
        AccessToken: accessToken,
      });
      await this.cognitoClient.send(command);
      return { res: true };
    } catch (err) {
      console.error((err as Cognito.InternalErrorException).name);
      console.error((err as Cognito.InternalErrorException).message);
      return {
        res: false,
        error: err as Cognito.InternalErrorException,
      };
    }
  };
  /**
   * サインアウト
   * @param accessToken サインイン中のユーザーのアクセストークン
   * @returns true:成功/false:失敗
   */
  public globalSignOut = async (
    accessToken: string
  ): Promise<{ result: boolean; error?: Cognito.InternalErrorException }> => {
    try {
      const command = new Cognito.GlobalSignOutCommand({
        AccessToken: accessToken,
      });
      await this.cognitoClient.send(command);
      return { result: true };
    } catch (err) {
      console.error((err as Cognito.InternalErrorException).name);
      console.error((err as Cognito.InternalErrorException).message);
      return {
        result: false,
        error: err as Cognito.InternalErrorException,
      };
    }
  };
  /**
   * ユーザーの削除
   * @param accessToken アクセストークン
   * @returns true:成功/false:失敗
   */
  public deleteUser = async (
    accessToken: string
  ): Promise<{ result: boolean; error?: Cognito.InternalErrorException }> => {
    try {
      const command = new Cognito.DeleteUserCommand({
        AccessToken: accessToken,
      });
      await this.cognitoClient.send(command);
      return { result: true };
    } catch (err) {
      console.error((err as Cognito.InternalErrorException).name);
      console.error((err as Cognito.InternalErrorException).message);
      return {
        result: false,
        error: err as Cognito.InternalErrorException,
      };
    }
  };
}
