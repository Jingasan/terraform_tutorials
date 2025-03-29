import * as Cognito from "@aws-sdk/client-cognito-identity-provider";
import { format } from "date-fns";
import { TZDate } from "@date-fns/tz";

/**
 * 日本時刻での日付を取得
 * @param date UNIX時刻
 * @returns 日本時刻での日付(yyyy/MM/dd)
 */
const getJSTDate = (date: Date): string => {
  const jstDate = new TZDate(date, "Asia/Tokyo");
  return format(jstDate, "yyyy-MM-dd");
};

/**
 * Cognitoクライアントクラス
 */
export class CognitoClient {
  /**
   * Cognitoクライアント
   */
  private cognitoClient = null;

  constructor(region: string) {
    this.cognitoClient = new Cognito.CognitoIdentityProviderClient({
      region,
    });
  }

  /**
   * 利用開始日に至っているかどうかチェック
   * @param todayDate 本日(日本時刻yyyy/MM/dd)
   * @param usageStartDate 利用開始日(日本時刻yyyy/MM/dd)
   * @returns true: 利用開始日に至っている, false: 利用開始日に至っていない
   */
  private checkAfterUsageStartDate = (
    todayDate: string,
    usageStartDate?: string
  ) => {
    try {
      if (!usageStartDate) return true;
      // 利用開始日(ミリ秒換算)を取得
      const usageStartDateMS = new Date(usageStartDate).getTime();
      // 現在ログイン日(ミリ秒換算)を取得
      const currentLoginDateMS = new Date(todayDate).getTime();
      return usageStartDateMS <= currentLoginDateMS;
    } catch (error) {
      console.error("checkAfterUsageStartDate Exception:", error);
      return false;
    }
  };

  /**
   * 管理者によるユーザー作成
   * @param userPoolId ユーザープールID
   * @param username 新規ユーザー名
   * @returns ユーザー情報/false:ユーザー作成失敗
   */
  public adminCreateUser = async (args: {
    userPoolId: string;
    username: string;
    usageStartDate?: string; // 日本時刻(yyyy-MM-dd)
    usageEndDate?: string; // 日本時刻(yyyy-MM-dd)
    userAttributes?: Cognito.AttributeType[];
  }): Promise<{
    res: Cognito.AdminCreateUserCommandOutput | false;
    error?: Cognito.InternalErrorException;
  }> => {
    const userAttributes = args.userAttributes ?? [];
    const dateRegex = /^\d{4}-\d{2}-\d{2}$/;
    if (
      args.usageStartDate &&
      args.usageEndDate &&
      !dateRegex.test(args.usageStartDate) &&
      !dateRegex.test(args.usageEndDate)
    ) {
      console.error(
        "usageStartDate and usageEndDate format must be yyyy-MM-dd."
      );
      return { res: false };
    }
    if (
      args.usageStartDate &&
      args.usageEndDate &&
      args.usageStartDate > args.usageEndDate
    ) {
      console.error("usageEndDate must be later than usageStartDate.");
      return { res: false };
    }
    if (args.usageStartDate) {
      userAttributes.push({
        Name: "custom:usage_start_date",
        Value: args.usageStartDate,
      });
    }
    if (args.usageEndDate) {
      userAttributes.push({
        Name: "custom:usage_end_date",
        Value: args.usageEndDate,
      });
    }
    try {
      // https://docs.aws.amazon.com/AWSJavaScriptSDK/v3/latest/client/cognito-identity-provider/command/AdminCreateUserCommand/
      const command = new Cognito.AdminCreateUserCommand({
        UserPoolId: args.userPoolId,
        Username: args.username,
        // ユーザー属性
        UserAttributes: userAttributes.length > 0 ? userAttributes : undefined,
        // 一時パスワードの送信方法(EMAIL/SMS)
        DesiredDeliveryMediums: ["EMAIL"],
        // 指定すると固定の一時パスワードを生成
        TemporaryPassword: undefined,
        // undefined:一時パスワードを送信擦る/SUPPRESS:一時パスワードを送信しない
        MessageAction: this.checkAfterUsageStartDate(
          getJSTDate(new Date()),
          args.usageStartDate
        )
          ? undefined
          : "SUPPRESS",
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
   * 仮パスワードの再発行
   * @param ユーザープールID
   * @param ユーザー名
   * @returns ユーザー情報/false:仮パスワードの再発行
   */
  public resendTemporaryPassword = async (args: {
    userPoolId: string;
    username: string;
  }): Promise<{
    res: Cognito.AdminCreateUserCommandOutput | false;
    error?: Cognito.InternalErrorException;
  }> => {
    try {
      // https://docs.aws.amazon.com/AWSJavaScriptSDK/v3/latest/client/cognito-identity-provider/command/AdminCreateUserCommand/
      const command = new Cognito.AdminCreateUserCommand({
        UserPoolId: args.userPoolId,
        Username: args.username,
        // 一時パスワードの送信方法(EMAIL/SMS)
        DesiredDeliveryMediums: ["EMAIL"],
        // 指定すると固定の一時パスワードを生成
        TemporaryPassword: undefined,
        // 一時パスワードの再送信
        MessageAction: "RESEND",
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
   * 仮パスワードかどうかのチェック
   * @param userPoolId ユーザープールID
   * @param username ユーザー名
   * @returns true:仮パスワード/false:仮パスワードでない
   */
  public isTempPassword = async (
    userPoolId: string,
    username: string
  ): Promise<{
    res: boolean;
    error?: Cognito.InternalErrorException;
  }> => {
    try {
      // https://docs.aws.amazon.com/AWSJavaScriptSDK/v3/latest/client/cognito-identity-provider/command/AdminGetUserCommand
      const command = new Cognito.AdminGetUserCommand({
        UserPoolId: userPoolId,
        Username: username,
      });
      const res = await this.cognitoClient.send(command);
      console.log(res);
      return { res: res.UserStatus === "FORCE_CHANGE_PASSWORD" };
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
   * 管理者によるパスワードの設定
   * @param userPoolId ユーザープールID
   * @param username ユーザー名
   * @param newPassword 新しいパスワード
   * @param permanent true:仮パスワードでなく、正式なパスワードとする
   * @returns true:成功/false:失敗
   */
  public adminSetUserPassword = async (
    userPoolId: string,
    username: string,
    newPassword: string,
    permanent?: boolean
  ): Promise<{
    res: boolean;
    error?: Cognito.InternalErrorException;
  }> => {
    try {
      // https://docs.aws.amazon.com/AWSJavaScriptSDK/v3/latest/client/cognito-identity-provider/command/AdminSetUserPasswordCommand
      const command = new Cognito.AdminSetUserPasswordCommand({
        UserPoolId: userPoolId,
        Username: username,
        Password: newPassword,
        Permanent: permanent ?? true,
      });
      const res = await this.cognitoClient.send(command);
      console.log(res);
      return {
        res: (await this.adminUpdatePasswordSetDate(userPoolId, username)).res,
      };
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
   * パスワード設定日時の更新
   * @param userPoolId ユーザープールID
   * @param username ユーザー名
   * @returns true:成功/false:失敗
   */
  public adminUpdatePasswordSetDate = async (
    userPoolId: string,
    username: string
  ): Promise<{ res: boolean; error?: Cognito.InternalErrorException }> => {
    // パスワード設定日時(ISO8601形式)をCognitoのユーザー属性に設定
    const passwordSetDate = getJSTDate(new Date());
    try {
      // https://docs.aws.amazon.com/AWSJavaScriptSDK/v3/latest/client/cognito-identity-provider/command/AdminUpdateUserAttributesCommand/
      const command = new Cognito.AdminUpdateUserAttributesCommand({
        UserPoolId: userPoolId,
        Username: username,
        UserAttributes: [
          {
            Name: "custom:password_set_date",
            Value: passwordSetDate,
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
   * ユーザー情報一覧の取得
   * @param userPoolId ユーザープールID
   * @param attributesToGet 取得する属性
   * @param filter 検索条件
   * @param limit 取得数の制限
   * @param paginationToken ページネーショントークン
   * @returns ユーザー情報一覧
   */
  public listUsers = async (args: {
    userPoolId: string;
    attributesToGet?: string[];
    filter?: string;
    limit?: number;
    paginationToken?: string;
  }): Promise<{
    res: Cognito.ListUsersCommandOutput | false;
    error?: Cognito.InternalErrorException;
  }> => {
    try {
      // https://docs.aws.amazon.com/AWSJavaScriptSDK/v3/latest/client/cognito-identity-provider/command/ListUsersCommand/
      const command = new Cognito.ListUsersCommand({
        UserPoolId: args.userPoolId,
        // 取得する属性を指定
        AttributesToGet: args.attributesToGet,
        // 検索条件（AttributesToGetとは併用不可）
        Filter: args.filter,
        // 取得数の制限
        Limit: args.limit,
        // ページネーショントークン
        // ListUsersCommandで取得できる上限数は60に限られているため、続きを取得する際には前回のレスポンスのページネーショントークンを指定
        PaginationToken: args.paginationToken,
      });
      const res = await this.cognitoClient.send(command);
      console.log(JSON.stringify(res, null, 2));
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
   * ユーザー情報一覧の取得
   * @param userPoolId ユーザープールID
   * @param attributes 取得する属性
   * @param filter 検索条件
   * @param limit 取得数の制限
   * @param paginationToken ページネーショントークン
   * @returns ユーザー情報一覧
   */
  public listAllUsers = async (args: {
    userPoolId: string;
    attributes?: string[];
    filter?: string;
  }): Promise<{
    res: Cognito.UserType[] | false;
    error?: Cognito.InternalErrorException;
  }> => {
    const users: Cognito.UserType[] = [];
    let paginationToken: string | undefined;
    do {
      const result = await this.listUsers({
        userPoolId: args.userPoolId,
        attributesToGet: args.attributes,
        filter: args.filter,
      });
      if (result.res) {
        users.push(...result.res.Users);
      } else {
        return { res: false, error: result.error };
      }
      paginationToken = result.res.PaginationToken;
    } while (paginationToken);
    return { res: users };
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
  public signUp = async (args: {
    userPoolClientId: string;
    password: string;
    username: string;
    userAttributes?: Cognito.AttributeType[];
  }): Promise<{
    res: Cognito.SignUpCommandOutput | false;
    error?: Cognito.InternalErrorException;
  }> => {
    // パスワード設定日時(ISO8601形式)をCognitoのユーザー属性に設定
    const passwordSetDate = getJSTDate(new Date());
    const userAttributes = args.userAttributes ?? [];
    userAttributes.push({
      Name: "custom:password_set_date",
      Value: passwordSetDate,
    });
    try {
      // https://docs.aws.amazon.com/AWSJavaScriptSDK/v3/latest/client/cognito-identity-provider/command/ConfirmSignUpCommand/
      const command = new Cognito.SignUpCommand({
        ClientId: args.userPoolClientId,
        Username: args.username,
        Password: args.password,
        UserAttributes: userAttributes,
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
   * 一段階目の認証
   * @param userPoolClientId アプリケーションクライアントID
   * @param username ユーザー名
   * @param password パスワード
   * @returns サインイン結果/false:失敗
   */
  public auth1st = async (
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
        AuthParameters: {
          USERNAME: username,
          PASSWORD: password,
        },
      });
      const res = await this.cognitoClient.send(command);
      console.log(JSON.stringify(res, null, "  "));
      console.log("--------------> " + res.ChallengeName);
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
   * 二段階目の認証
   * @param userPoolClientId アプリケーションクライアントID
   * @param username ユーザー名
   * @param password パスワード
   * @returns サインイン結果/false:失敗
   */
  public auth2nd = async (
    userPoolClientId: string,
    username: string
  ): Promise<{
    res: Cognito.InitiateAuthCommandOutput | false;
    error?: Cognito.InternalErrorException;
  }> => {
    try {
      // https://docs.aws.amazon.com/AWSJavaScriptSDK/v3/latest/client/cognito-identity-provider/command/InitiateAuthCommand
      const command = new Cognito.InitiateAuthCommand({
        ClientId: userPoolClientId,
        // ユーザープールの設定でALLOW_CUSTOM_AUTHの有効化が必要
        AuthFlow: Cognito.AuthFlowType.CUSTOM_AUTH,
        AuthParameters: {
          CHALLENGE_NAME: "USER_PASSWORD_AUTH",
          USERNAME: username,
        },
      });
      const res = await this.cognitoClient.send(command);
      console.log(JSON.stringify(res, null, "  "));
      console.log("--------------> " + res.ChallengeName);
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
      case "CUSTOM_CHALLENGE":
        return {
          USERNAME: args.username,
          ANSWER: args.code, // Custom Challenge Answer
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
      console.log(JSON.stringify(res, null, "  "));
      console.log("----------------> " + res.ChallengeName);
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
   * メールアドレス変更
   * @param email メールアドレス
   * @param accessToken アクセストークン
   * @returns true:成功/false:失敗
   */
  public changeEmail = async (
    email: string,
    accessToken: string
  ): Promise<{ res: boolean; error?: Cognito.InternalErrorException }> => {
    try {
      // https://docs.aws.amazon.com/AWSJavaScriptSDK/v3/latest/client/cognito-identity-provider/command/UpdateUserAttributesCommand/
      const command = new Cognito.UpdateUserAttributesCommand({
        AccessToken: accessToken,
        UserAttributes: [
          {
            Name: "email",
            Value: email,
          },
          //   {
          //     Name: "email_verified",
          //     Value: "false",
          //   },
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
      return { res: (await this.updatePasswordSetDate(accessToken)).res };
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
   * パスワード設定日時の更新
   * @param accessToken アクセストークン
   * @returns true:成功/false:失敗
   */
  public updatePasswordSetDate = async (
    accessToken: string
  ): Promise<{ res: boolean; error?: Cognito.InternalErrorException }> => {
    // パスワード設定日時(ISO8601形式)をCognitoのユーザー属性に設定
    const passwordSetDate = getJSTDate(new Date());
    try {
      // https://docs.aws.amazon.com/AWSJavaScriptSDK/v3/latest/client/cognito-identity-provider/command/UpdateUserAttributesCommand/
      const command = new Cognito.UpdateUserAttributesCommand({
        AccessToken: accessToken,
        UserAttributes: [
          {
            Name: "custom:password_set_date",
            Value: passwordSetDate,
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
