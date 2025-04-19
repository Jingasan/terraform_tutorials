#============================================================
# Cognito
#============================================================

# ユーザープールの作成
resource "aws_cognito_user_pool" "user_pool" {
  # ユーザープール名
  name = var.project_name
  # ユーザープールの料金プラン(LITE/ESSENTIALS/PLUS)
  user_pool_tier = "ESSENTIALS"
  # ユーザー名の他に認証での利用を許可する属性(email/phone_number/preferred_username)
  # username_attributesと同時利用不可
  # alias_attributes = ["email"]
  # サインアップ時にユーザー名の代わりに利用可能な属性(email/phone_number)
  # alias_attributesと同時利用不可
  username_attributes = ["email"]
  # ユーザー名の要件
  username_configuration {
    # false(default): ユーザー名の大文字と小文字を区別しない
    case_sensitive = false
  }
  # パスワードのポリシー
  password_policy {
    minimum_length                   = 8     # 最低文字数
    require_uppercase                = false # 大文字を必須とするか
    require_lowercase                = false # 小文字を必須とするか
    require_numbers                  = false # 数字を必須とするか
    require_symbols                  = false # 記号を必須とするか
    temporary_password_validity_days = 7     # 管理者によって設定された仮パスワードの有効期間(日)
  }
  # サインインポリシー
  sign_in_policy {
    # 最優先の認証方式
    allowed_first_auth_factors = ["PASSWORD"]
  }
  # INACTIVE(default):ユーザープールの削除を許可/ACTIVE:ユーザープールの削除を拒否
  deletion_protection = "INACTIVE"
  # 多要素認証(MFA)の強制 ON(default)/OFF/OPTIONAL
  mfa_configuration = "ON"
  # MFA設定
  software_token_mfa_configuration {
    enabled = false # TOTPを利用せず、メールOTPを利用する
  }
  # メールOTP(Email MFA)の設定
  email_mfa_configuration {
    # メールタイトル
    subject = "[${var.project_name}] ワンタイムパスワード"
    # メール本文
    message = "ワンタイムパスワードは{####}です。"
  }
  sms_configuration {
    external_id    = "cognito-sms-${local.lower_random_hex}"
    sns_caller_arn = aws_iam_role.cognito_sms_role.arn
  }
  # ユーザーアカウントの復旧方法
  account_recovery_setting {
    # メールによる復旧を優先度1に設定(verifed_email/verified_phone_number)
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
    # 電話番号による復旧を優先度2に設定
    recovery_mechanism {
      name     = "verified_phone_number"
      priority = 2
    }
  }
  # 管理者によるユーザー作成の設定
  admin_create_user_config {
    # true:管理者によるユーザー作成のみ許可/false:ユーザーによるサインアップを有効化
    allow_admin_create_user_only = false
    # 管理者によるユーザー作成時に送信する招待メールのテンプレート
    invite_message_template {
      # メールタイトル
      email_subject = "[${var.project_name}] ユーザー登録完了"
      # メール本文
      email_message = "{username}様<br><br>初期パスワードは{####}です。<br>ログインURLは以下となります。<br>https://xxx<br>初回ログイン後にパスワード変更が必要です。"
      # SMSメッセージ
      sms_message = "{username}様<br><br>初期パスワードは{####}です。<br>ログインURLは以下となります。<br>https://xxx<br>初回ログイン後にパスワード変更が必要です。"
    }
  }
  # 追加のカスタム属性(最大50個まで)
  # Cognito既定のメールアドレス
  schema {
    name                     = "email"  # データ型
    attribute_data_type      = "String" # 属性名
    required                 = true     # 必須か true:必須(カスタム属性では必須にできない)
    mutable                  = true     # 可変か true:可変
    developer_only_attribute = false    # ユーザーによる登録を許可するか false:許可/true:拒否
  }
  # Cognito既定の電話番号
  schema {
    name                     = "phone_number" # データ型
    attribute_data_type      = "String"       # 属性名
    required                 = true           # 必須か true:必須(カスタム属性では必須にできない)
    mutable                  = true           # 可変か true:可変
    developer_only_attribute = false          # ユーザーによる登録を許可するか false:許可/true:拒否
  }
  # Cognito既定の姓名
  schema {
    attribute_data_type      = "String" # データ型
    name                     = "name"   # 属性名
    required                 = true     # 必須か true:必須(カスタム属性では必須にできない)
    mutable                  = true     # 可変か true:可変
    developer_only_attribute = false    # ユーザーによる登録を許可するか false:許可/true:拒否
    string_attribute_constraints {
      max_length = "60"
      min_length = "1"
    }
  }
  # Cognito既定の姓
  schema {
    attribute_data_type      = "String"      # データ型
    name                     = "family_name" # 属性名
    required                 = true          # 必須か true:必須(カスタム属性では必須にできない)
    mutable                  = true          # 可変か true:可変
    developer_only_attribute = false         # ユーザーによる登録を許可するか false:許可/true:拒否
    string_attribute_constraints {
      max_length = "30"
      min_length = "1"
    }
  }
  # Customの姓(カナ)
  schema {
    attribute_data_type      = "String"           # データ型
    name                     = "family_name_kana" # 属性名(「custom:属性名」で利用する)
    required                 = false              # 必須か true:必須(カスタム属性では必須にできない)
    mutable                  = true               # 可変か true:可変
    developer_only_attribute = false              # ユーザーによる登録を許可するか false:許可/true:拒否
    string_attribute_constraints {
      max_length = "30"
      min_length = "1"
    }
  }
  # Cognito既定の名
  schema {
    attribute_data_type      = "String"     # データ型
    name                     = "given_name" # 属性名
    required                 = true         # 必須か true:必須(カスタム属性では必須にできない)
    mutable                  = true         # 可変か true:可変
    developer_only_attribute = false        # ユーザーによる登録を許可するか false:許可/true:拒否
    string_attribute_constraints {
      max_length = "30"
      min_length = "1"
    }
  }
  # Customの名(カナ)
  schema {
    attribute_data_type      = "String"          # データ型
    name                     = "given_name_kana" # 属性名(「custom:属性名」で利用する)
    required                 = false             # 必須か true:必須(カスタム属性では必須にできない)
    mutable                  = true              # 可変か true:可変
    developer_only_attribute = false             # ユーザーによる登録を許可するか false:許可/true:拒否
    string_attribute_constraints {
      max_length = "30"
      min_length = "1"
    }
  }
  # Cognito既定の生年月日
  schema {
    name                     = "birthdate" # データ型
    attribute_data_type      = "String"    # 属性名
    required                 = true        # 必須か true:必須(カスタム属性では必須にできない)
    mutable                  = true        # 可変か true:可変
    developer_only_attribute = false       # ユーザーによる登録を許可するか false:許可/true:拒否
  }
  # Cognito既定の住所
  schema {
    name                     = "address" # データ型
    attribute_data_type      = "String"  # 属性名
    required                 = true      # 必須か true:必須(カスタム属性では必須にできない)
    mutable                  = true      # 可変か true:可変
    developer_only_attribute = false     # ユーザーによる登録を許可するか false:許可/true:拒否
    string_attribute_constraints {
      max_length = "1000"
      min_length = "1"
    }
  }
  # Customの申請区分（個人／団体）
  schema {
    attribute_data_type      = "String"        # データ型
    name                     = "request_class" # 属性名(「custom:属性名」で利用する)
    required                 = false           # 必須か true:必須(カスタム属性では必須にできない)
    mutable                  = true            # 可変か true:可変
    developer_only_attribute = false           # ユーザーによる登録を許可するか false:許可/true:拒否
    string_attribute_constraints {
      max_length = "4"
      min_length = "1"
    }
  }
  # Customの利用目的
  schema {
    attribute_data_type      = "String"  # データ型
    name                     = "purpose" # 属性名(「custom:属性名」で利用する)
    required                 = false     # 必須か true:必須(カスタム属性では必須にできない)
    mutable                  = true      # 可変か true:可変
    developer_only_attribute = false     # ユーザーによる登録を許可するか false:許可/true:拒否
    string_attribute_constraints {
      max_length = "1000"
      min_length = "1"
    }
  }
  # ユーザーがサインアップした際に自動的に検証される属性(email/phone_number)
  auto_verified_attributes = ["email"]
  # メッセージ送信設定
  email_configuration {
    # メールプロバイダーの設定
    # COGNITO_DEFAULT:CognitoでEメールを送信
    # DEVELOPER(default):Amazon SESでEメールを送信(推奨)
    email_sending_account = "DEVELOPER"
    # SESで認証するメールアドレスのARN
    source_arn = "arn:aws:ses:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:identity/${var.from_email_address}"
    # 送信元メールアドレス
    from_email_address = var.from_email_address
  }
  # ユーザーの属性情報更新の設定
  user_attribute_update_settings {
    # 更新するために認証が必要な属性(email/phone_number)
    attributes_require_verification_before_update = ["email"]
  }
  # 検証メッセージのテンプレート
  verification_message_template {
    # 検証オプション
    # CONFIRM_WITH_CODE:検証コードに検証
    # CONFIRM_WITH_LINK:検証用リンク押下による検証
    default_email_option = "CONFIRM_WITH_CODE"
    # 検証コード送信メールのタイトル(検証コードによる検証の場合)
    email_subject = "[${var.project_name}] 検証コード"
    # 検証コード送信メールの本文(検証コードによる検証の場合)
    email_message = "検証コードは「{####}」です。"
    # 検証コード送信メールのタイトル(検証用リンク押下による検証の場合)
    email_subject_by_link = "[${var.project_name}] 検証リンク"
    # 検証コード送信メールの本文(検証用リンク押下による検証の場合)
    email_message_by_link = "{##こちら##}の検証リンクを押下してください。"
    # 検証コード送信SMSの本文
    sms_message = "検証コードは「{####}」です。"
  }
  # ユーザープールのアドオン設定
  user_pool_add_ons {
    # 高度なセキュリティ設定(OFF/AUDIT/ENFORCED)
    advanced_security_mode = "OFF"
  }
  # Lambdaトリガーの設定
  # 設定すると、ユーザープールにアクションがあった際にLambda関数を呼び出すことができる
  lambda_config {
    # ユーザーログイン時にLambda経由でログイン通知をユーザーに送信
    post_authentication = aws_lambda_function.lambda_cognito_login_notify.arn
  }
  # タグ
  tags = {
    "name" = var.project_name
  }
}

# アプリケーションクライアントの作成
resource "aws_cognito_user_pool_client" "user_pool" {
  # ユーザープールクライアント名
  name = var.project_name
  # ユーザープールクライアントを作成する対象のユーザープールID
  user_pool_id = aws_cognito_user_pool.user_pool.id
  # シークレットを作成するか false(default):作成しない
  generate_secret = false
  # 許可する認証フロー
  explicit_auth_flows = [
    "ALLOW_ADMIN_USER_PASSWORD_AUTH", // 管理ユーザーによるユーザー名とパスワードでの認証(サーバーサイドで利用)
    "ALLOW_CUSTOM_AUTH",              // Lambdaトリガーベースのカスタム認証
    "ALLOW_REFRESH_TOKEN_AUTH",       // リフレッシュトークンベースの認証
    "ALLOW_USER_PASSWORD_AUTH",       // ユーザー名とパスワードでの認証
    "ALLOW_USER_SRP_AUTH",            // SRP(セキュアリモートパスワード)プロトコルベースの認証(最もセキュアなため、利用推奨)
  ]
  # 認証フローセッションの持続期間(分)(3-15分の範囲で指定)
  auth_session_validity = 3
  # 各トークンの有効期限の単位: seconds/minutes/hours/days
  token_validity_units {
    id_token      = "seconds" # IDトークン
    access_token  = "seconds" # アクセストークン
    refresh_token = "seconds" # リフレッシュトークン
  }
  # IDトークンの有効期限(5分-1日の範囲で指定)
  id_token_validity = var.cognito_id_token_validity
  # アクセストークンの有効期限(5分-1日の範囲で指定)
  access_token_validity = var.cognito_access_token_validity
  # リフレッシュトークンの有効期限
  # 60分-10年の範囲で指定, IDトークン/アクセストークンよりも長い時間を指定すること
  refresh_token_validity = var.cognito_refresh_token_validity
  # トークンの取り消しを有効化
  enable_token_revocation = true
  # ユーザー存在エラーの防止
  prevent_user_existence_errors = "ENABLED"
  # 許可するサインイン後のリダイレクト先URL群
  callback_urls = []
  # 許可するサインアウト後のリダイレクト先URL群
  logout_urls = []
  # サポートするプロバイダー
  supported_identity_providers = ["COGNITO"]
  # false(default)/true:アプリケーションクライアントでOAuth2.0の機能を利用可能とする
  allowed_oauth_flows_user_pool_client = false
  # OAuth2.0で利用する認可フロー(code/implicit/client_credentials)
  allowed_oauth_flows = []
  # 許可するOAuth2.0のスコープ(openid/aws.cognito.signin.user.admin)
  allowed_oauth_scopes = []
}

# ユーザープールドメインの有効化
# ドメインが有効になり、HostedUI(ログイン画面)が利用可能になる
# resource "aws_cognito_user_pool_domain" "user_pool" {
#   # ドメイン
#   domain = var.project_name
#   # 対象のユーザープールID
#   user_pool_id = aws_cognito_user_pool.user_pool.id
# }

# バックエンドの.envファイル生成
resource "local_file" "env" {
  # 出力先
  filename = "../backend/.env"
  # 出力ファイルのパーミッション
  file_permission = "0644"
  # 出力ファイルの内容
  content = <<DOC
USER_POOL_ID=${aws_cognito_user_pool.user_pool.id}
APPLICATION_CLIENT_ID=${aws_cognito_user_pool_client.user_pool.id}
DOC
}

# ユーザープールIDの表示
output "pool_id" {
  description = "ユーザープールID"
  value       = aws_cognito_user_pool.user_pool.id
}

# アプリケーションクライアントIDの表示
output "client_id" {
  description = "アプリケーションクライアントID"
  value       = aws_cognito_user_pool_client.user_pool.id
}



#########################################



resource "aws_iam_role" "cognito_sms_role" {
  name = "cognito_sms_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "cognito-idp.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "cognito_sms_policy" {
  name        = "CognitoSMSPolicy"
  description = "Policy to allow Cognito to send SMS via SNS"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "sns:publish"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cognito_sms_policy_attachment" {
  role       = aws_iam_role.cognito_sms_role.name
  policy_arn = aws_iam_policy.cognito_sms_policy.arn
}
