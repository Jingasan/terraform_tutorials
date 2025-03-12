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
   * 管理者によるユーザー作成
   * @param userPoolId ユーザープールID
   * @param username 新規ユーザー名
   * @returns ユーザー情報/false:ユーザー作成失敗
   */
  public adminCreateUser = async (
    userPoolId: string,
    username: string,
    email: string,
    familyName: string,
    givenName: string,
    familyNameKana: string,
    givenNameKana: string,
    birthdate: string,
    address: string,
    tel: string,
    requestClass: string,
    purpose: string
  ): Promise<{
    res: Cognito.AdminCreateUserCommandOutput | false;
    error?: Cognito.InternalErrorException;
  }> => {
    try {
      // https://docs.aws.amazon.com/AWSJavaScriptSDK/v3/latest/client/cognito-identity-provider/command/AdminCreateUserCommand/
      const command = new Cognito.AdminCreateUserCommand({
        UserPoolId: userPoolId,
        Username: username,
        TemporaryPassword: "Password1234!",
        UserAttributes: [
          { Name: "email", Value: email },
          { Name: "email_verified", Value: "true" }, // メールアドレス検証を行う場合はtrueにしない
          { Name: "phone_number", Value: tel },
          { Name: "phone_number_verified", Value: "true" },
          { Name: "name", Value: familyName + " " + givenName },
          { Name: "family_name", Value: familyName },
          { Name: "given_name", Value: givenName },
          { Name: "custom:family_name_kana", Value: familyNameKana },
          { Name: "custom:given_name_kana", Value: givenNameKana },
          { Name: "birthdate", Value: birthdate },
          { Name: "address", Value: address },
          { Name: "custom:request_class", Value: requestClass },
          { Name: "custom:purpose", Value: purpose },
        ],
        DesiredDeliveryMediums: ["EMAIL"],
      });
      const res = await this.cognitoClient.send(command);
      console.log(res);
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
   * 管理者によるメールアドレスの検証
   * @param userPoolId ユーザープールID
   * @param username ユーザー名
   * @returns true:成功/false:失敗
   */
  public adminVerifyEmail = async (
    userPoolId: string,
    username: string
  ): Promise<{
    res: boolean;
    error?: Cognito.InternalErrorException;
  }> => {
    try {
      // https://docs.aws.amazon.com/AWSJavaScriptSDK/v3/latest/client/cognito-identity-provider/command/AdminUpdateUserAttributesCommand
      const command = new Cognito.AdminUpdateUserAttributesCommand({
        UserPoolId: userPoolId,
        Username: username,
        UserAttributes: [
          {
            Name: "email_verified",
            Value: "true",
          },
        ],
      });
      const res = await this.cognitoClient.send(command);
      console.log(res);
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
   * ユーザーのメールアドレスに対し、メールアドレスの検証を依頼（対象のメールアドレスに対し、検証コードが送信される）
   * @param accessToken アクセストークン
   * @returns false:失敗
   */
  public verifyEmail = async (
    accessToken: string
  ): Promise<{
    res: Cognito.GetUserAttributeVerificationCodeCommandOutput | false;
    error?: Cognito.InternalErrorException;
  }> => {
    try {
      // https://docs.aws.amazon.com/AWSJavaScriptSDK/v3/latest/client/cognito-identity-provider/#:~:text=GetUserAttributeVerificationCodeCommand
      const command = new Cognito.GetUserAttributeVerificationCodeCommand({
        AccessToken: accessToken,
        AttributeName: "email",
      });
      const res = await this.cognitoClient.send(command);
      console.log(res);
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
   * メールアドレスの検証（対象のメールアドレスに届いた検証コードを入力してメールアドレスを検証）
   * @param accessToken アクセストークン
   * @param verificationCode 検証コード
   * @returns true:成功/false:失敗
   */
  public confirmVerifyEmail = async (
    accessToken: string,
    verificationCode: string
  ): Promise<{
    res: boolean;
    error?: Cognito.InternalErrorException;
  }> => {
    try {
      // https://docs.aws.amazon.com/AWSJavaScriptSDK/v3/latest/client/cognito-identity-provider/#:~:text=GetUserAttributeVerificationCodeCommand
      const command = new Cognito.VerifyUserAttributeCommand({
        AccessToken: accessToken,
        AttributeName: "email",
        Code: verificationCode,
      });
      const res = await this.cognitoClient.send(command);
      console.log(res);
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
   * 管理者によるユーザー削除
   * @param userPoolId ユーザープールID
   * @param username 削除対象のユーザー名
   * @returns false:ユーザー削除失敗
   */
  public adminDeleteUser = async (
    userPoolId: string,
    username: string
  ): Promise<{
    res: boolean;
    error?: Cognito.InternalErrorException;
  }> => {
    try {
      // https://docs.aws.amazon.com/AWSJavaScriptSDK/v3/latest/client/cognito-identity-provider/command/AdminDeleteUserCommand/
      const command = new Cognito.AdminDeleteUserCommand({
        UserPoolId: userPoolId,
        Username: username,
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
   * サインアップ（ユーザーによるアカウント作成）
   * @param userPoolClientId アプリケーションクライアントID
   * @param username 新規ユーザー名
   * @param email メールアドレス
   * @param password パスワード
   * @returns ユーザー情報/false:サインアップ失敗
   */
  public signUp = async (
    userPoolClientId: string,
    password: string,
    username: string,
    email: string,
    familyName: string,
    givenName: string,
    familyNameKana: string,
    givenNameKana: string,
    birthdate: string,
    address: string,
    tel: string,
    requestClass: string,
    purpose: string
  ): Promise<{
    res: Cognito.SignUpCommandOutput | false;
    error?: Cognito.InternalErrorException;
  }> => {
    try {
      // https://docs.aws.amazon.com/AWSJavaScriptSDK/v3/latest/client/cognito-identity-provider/command/ConfirmSignUpCommand/
      const command = new Cognito.SignUpCommand({
        ClientId: userPoolClientId,
        Username: username,
        Password: password,
        UserAttributes: [
          { Name: "email", Value: email },
          { Name: "phone_number", Value: tel },
          { Name: "name", Value: familyName + " " + givenName },
          { Name: "family_name", Value: familyName },
          { Name: "given_name", Value: givenName },
          { Name: "custom:family_name_kana", Value: familyNameKana },
          { Name: "custom:given_name_kana", Value: givenNameKana },
          { Name: "birthdate", Value: birthdate },
          { Name: "address", Value: address },
          { Name: "custom:request_class", Value: requestClass },
          { Name: "custom:purpose", Value: purpose },
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
      // https://docs.aws.amazon.com/AWSJavaScriptSDK/v3/latest/client/cognito-identity-provider/command/ConfirmSignUpCommand
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
   * @param userPoolClientId アプリケーションクライアントID
   * @param username ユーザー名
   * @param password パスワード
   * @returns サインイン結果/false:失敗
   */
  public initiateAuth = async (
    userPoolClientId: string,
    username: string,
    password: string
  ): Promise<{
    res: Cognito.InitiateAuthCommandOutput | false;
    error?: Cognito.InternalErrorException;
  }> => {
    try {
      // https://docs.aws.amazon.com/AWSJavaScriptSDK/v3/latest/client/cognito-identity-provider/command/InitiateAuthCommand
      const command = new Cognito.InitiateAuthCommand({
        ClientId: userPoolClientId,
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
   * 認証チャレンジレスポンスの取得
   * @param args
   * @returns 認証チャレンジレスポンス
   */
  private getChallengeResponse = (args: {
    challengeName: Cognito.ChallengeNameType;
    username: string;
    code: string;
  }): Record<string, string> => {
    switch (args.challengeName) {
      case "EMAIL_OTP":
        return {
          USERNAME: args.username,
          EMAIL_OTP_CODE: args.code, // EMail One Time Password
        };
      case "SMS_OTP":
        return {
          USERNAME: args.username,
          SMS_OTP_CODE: args.code, // SMS One Time Password
        };
      case "SOFTWARE_TOKEN_MFA":
        return {
          USERNAME: args.username,
          SOFTWARE_TOKEN_MFA_CODE: args.code, // Authenticator Code
        };
      case "SMS_MFA":
        return {
          USERNAME: args.username,
          SMS_MFA_CODE: args.code, // SMS MFA Code
        };
      case "MFA_SETUP":
        return {
          USERNAME: args.username,
          SESSION: args.code, // Session ID from VerifySoftwareToken
        };
      case "SELECT_MFA_TYPE":
        return {
          USERNAME: args.username,
          ANSWER: args.code, // SMS_MFA or SOFTWARE_TOKEN_MFA
        };
      case "NEW_PASSWORD_REQUIRED":
        return {
          USERNAME: args.username,
          NEW_PASSWORD: args.code, // New Password
        };
      default:
        return {};
    }
  };

  /**
   * MFA認証やセキュアリモートパスワード(SRP)などの認証チャレンジに対する回答
   * @param userPoolClientId アプリケーションクライアントID
   * @param challengeName 認証チャレンジ名
   * @param username 認証ユーザー名
   * @param code 認証コード／パスワード
   * @returns 認証チャレンジに対する回答の結果/false:失敗
   */
  public respondToAuthChallenge = async (
    userPoolClientId: string,
    challengeName: Cognito.ChallengeNameType,
    username: string,
    code: string,
    session: string
  ): Promise<{
    res: Cognito.RespondToAuthChallengeCommandOutput | false;
    error?: Cognito.InternalErrorException;
  }> => {
    try {
      // https://docs.aws.amazon.com/AWSJavaScriptSDK/v3/latest/client/cognito-identity-provider/command/RespondToAuthChallengeCommand/
      const command = new Cognito.RespondToAuthChallengeCommand({
        ChallengeName: challengeName,
        ClientId: userPoolClientId,
        ChallengeResponses: this.getChallengeResponse({
          challengeName,
          username,
          code,
        }),
        Session: session,
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
   * @param userPoolClientId アプリケーションクライアントID
   * @param refreshToken リフレッシュトークン
   * @returns 更新後のトークン/false:失敗
   */
  public updateToken = async (
    userPoolClientId: string,
    refreshToken: string
  ): Promise<{
    res: Cognito.InitiateAuthCommandOutput | false;
    error?: Cognito.InternalErrorException;
  }> => {
    try {
      // https://docs.aws.amazon.com/AWSJavaScriptSDK/v3/latest/client/cognito-identity-provider/command/InitiateAuthCommand
      const command = new Cognito.InitiateAuthCommand({
        ClientId: userPoolClientId,
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
      // https://docs.aws.amazon.com/AWSJavaScriptSDK/v3/latest/client/cognito-identity-provider/command/GetUserCommand
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
      // https://docs.aws.amazon.com/AWSJavaScriptSDK/v3/latest/client/cognito-identity-provider/command/ChangePasswordCommand
      const command = new Cognito.ChangePasswordCommand({
        PreviousPassword: previousPassword,
        ProposedPassword: proposedPassword,
        AccessToken: accessToken,
      });
      const res = await this.cognitoClient.send(command);
      console.log(res);
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
   * パスワードリセット
   * @param userPoolClientId アプリケーションクライアントID
   * @param username パスワードリセット対象のユーザー名
   * @returns パスワードリセット結果/false:失敗
   */
  public forgotPassword = async (
    userPoolClientId: string,
    username: string
  ): Promise<{
    res: Cognito.ForgotPasswordCommandOutput | false;
    error?: Cognito.InternalErrorException;
  }> => {
    try {
      // https://docs.aws.amazon.com/AWSJavaScriptSDK/v3/latest/client/cognito-identity-provider/command/ForgotPasswordCommand/
      const command = new Cognito.ForgotPasswordCommand({
        ClientId: userPoolClientId,
        Username: username,
      });
      const res = await this.cognitoClient.send(command);
      console.log(res);
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
   * パスワードリセットの検証(Confirm)
   * @param userPoolClientId アプリケーションクライアントID
   * @param username パスワードリセット対象のユーザー名
   * @param confirmationCode 検証コード
   * @param newPassword 新しいパスワード
   * @returns true:成功/false:失敗
   */
  public confirmForgotPassword = async (
    userPoolClientId: string,
    username: string,
    confirmationCode: string,
    newPassword: string
  ): Promise<{
    res: boolean;
    error?: Cognito.InternalErrorException;
  }> => {
    try {
      // https://docs.aws.amazon.com/AWSJavaScriptSDK/v3/latest/client/cognito-identity-provider/command/ConfirmForgotPasswordCommand/
      const command = new Cognito.ConfirmForgotPasswordCommand({
        ClientId: userPoolClientId,
        Username: username,
        ConfirmationCode: confirmationCode,
        Password: newPassword,
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
      // https://docs.aws.amazon.com/AWSJavaScriptSDK/v3/latest/client/cognito-identity-provider/command/GlobalSignOutCommand
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
      // https://docs.aws.amazon.com/AWSJavaScriptSDK/v3/latest/client/cognito-identity-provider/command/DeleteUserCommand
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
