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
    password: string
  ): Promise<{
    result: boolean;
    output: Cognito.SignUpCommandOutput | string;
  }> => {
    try {
      const command = new Cognito.SignUpCommand({
        ClientId: clientId,
        Username: username,
        Password: password,
        UserAttributes: [{ Name: "email", Value: email }],
      });
      const res = await this.cognitoClient.send(command);
      return { result: true, output: res };
    } catch (err) {
      console.error((err as Cognito.InternalErrorException).name);
      return {
        result: false,
        output: (err as Cognito.InternalErrorException).name,
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
    result: boolean;
    output: string;
  }> => {
    try {
      const command = new Cognito.ConfirmSignUpCommand({
        ClientId: userPoolClientId,
        Username: username,
        ConfirmationCode: confirmationCode,
      });
      await this.cognitoClient.send(command);
      return { result: true, output: "" };
    } catch (err) {
      console.error((err as Cognito.InternalErrorException).name);
      return {
        result: false,
        output: (err as Cognito.InternalErrorException).name,
      };
    }
  };
  /**
   * サインイン
   * @param userPoolId ユーザープールID
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
    result: boolean;
    output: Cognito.AdminInitiateAuthCommandOutput | string;
  }> => {
    try {
      const command = new Cognito.InitiateAuthCommand({
        ClientId: clientId,
        // ユーザープールの設定でALLOW_USER_PASSWORD_AUTHの有効化が必要
        AuthFlow: Cognito.AuthFlowType.USER_PASSWORD_AUTH,
        AuthParameters: { USERNAME: username, PASSWORD: password },
      });
      const res = await this.cognitoClient.send(command);
      return { result: true, output: res };
    } catch (err) {
      console.error((err as Cognito.InternalErrorException).name);
      return {
        result: false,
        output: (err as Cognito.InternalErrorException).name,
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
  ): Promise<{ result: boolean; output: string }> => {
    try {
      const command = new Cognito.ChangePasswordCommand({
        PreviousPassword: previousPassword,
        ProposedPassword: proposedPassword,
        AccessToken: accessToken,
      });
      await this.cognitoClient.send(command);
      return { result: true, output: "" };
    } catch (err) {
      console.error((err as Cognito.InternalErrorException).name);
      return {
        result: false,
        output: (err as Cognito.InternalErrorException).name,
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
  ): Promise<{ result: boolean; output: string }> => {
    try {
      const command = new Cognito.GlobalSignOutCommand({
        AccessToken: accessToken,
      });
      await this.cognitoClient.send(command);
      return { result: true, output: "" };
    } catch (err) {
      console.error((err as Cognito.InternalErrorException).name);
      return {
        result: false,
        output: (err as Cognito.InternalErrorException).name,
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
  ): Promise<{ result: boolean; output: string }> => {
    try {
      const command = new Cognito.DeleteUserCommand({
        AccessToken: accessToken,
      });
      await this.cognitoClient.send(command);
      return { result: true, output: "" };
    } catch (err) {
      console.error((err as Cognito.InternalErrorException).name);
      return {
        result: false,
        output: (err as Cognito.InternalErrorException).name,
      };
    }
  };
}
