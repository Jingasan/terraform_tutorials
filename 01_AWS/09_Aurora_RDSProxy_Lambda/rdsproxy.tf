#============================================================
# RDS Proxy
#============================================================

# RDS Proxyの作成
resource "aws_db_proxy" "rds_proxy" {
  # エンジンファミリー
  engine_family = var.rds_proxy_engine_family
  # RDSへの接続を許可するIAMロールの指定
  role_arn = aws_iam_role.rds_proxy.arn
  # プロキシ識別子
  name = "${var.project_name}-${var.aurora_engine}-proxy"
  # アプリケーションからののアイドル接続のタイムアウト（秒）（最小1分，最大8時間）
  idle_client_timeout = var.rds_proxy_idle_client_timeout
  # 認証の設定
  auth {
    # 認証方式の指定
    auth_scheme = "SECRETS"
    # Secrets ManagerのSecretのArn指定
    secret_arn = aws_secretsmanager_secret.rds.arn
    # IAM認証するかどうか（REQUIRED：する／DISABLED：しない）
    # IAM認証を有効化すると、RDSProxyへの接続はRDSのパスワードではなく、RDSから発行したIAM認証トークンを使って行うことになる。
    # IAM認証トークンは15分の有効期限があり、外部に漏れてしまっても有効期限が切れると接続できなくなる為、利用するとセキュリティ性が高くなる。
    # 有効期限が15分である為、Secrets ManagerでLambdaを利用したDB接続パスワードの定期ローテーションも行う必要がなくなる。
    # また、IAM認証を利用することで、IAMポリシーの階層でアクセス権限を管理できるようになる。（例：LambdaだけにDB接続を許可するなど）
    # 一方で、IAM認証を利用する場合は定期的にIAM認証トークンを取得し直し、DBとのコネクションを張り直す必要がある。
    iam_auth = "DISABLED"
    # 説明文
    description = var.project_name
  }
  # TLS接続の有効化
  require_tls = true
  # VPCサブネットの指定
  vpc_subnet_ids = [for value in aws_subnet.private : value.id]
  # VPCセキュリティグループの指定
  vpc_security_group_ids = [aws_security_group.rds_proxy.id]
  # タグ
  tags = {
    Name              = "${var.project_name}-aurora-postgresql"
    ProjectName       = var.project_name
    ResourceCreatedBy = "terraform"
  }
}

# ターゲットグループの設定
resource "aws_db_proxy_default_target_group" "rds_proxy" {
  # 設定の対象とするRDS Proxy名
  db_proxy_name = aws_db_proxy.rds_proxy.name
  # コネクションプールの設定
  connection_pool_config {
    # DBの最大接続数に対して許容するRDS Proxyからの最大接続数（％）
    max_connections_percent = var.rds_proxy_max_connections_percent
    # DBの最大接続数に対して許容するRDS Proxyからの最大アイドル接続数（％）
    max_idle_connections_percent = var.rds_proxy_max_idle_connections_percent
    # プールから借用したDB接続のタイムアウト時間（秒）（最大5分）
    connection_borrow_timeout = var.rds_proxy_connection_borrow_timeout
  }
}

# RDS Proxyの対象とするRDSの指定
resource "aws_db_proxy_target" "target_db" {
  # 設定の対象とするRDS Proxy名
  db_proxy_name = aws_db_proxy.rds_proxy.name
  # 設定関連付け先のターゲットグループ名の指定
  target_group_name = aws_db_proxy_default_target_group.rds_proxy.name
  # RDS Proxyの対象とするAuroraクラスターの指定
  db_cluster_identifier = aws_rds_cluster.aurora_postgresql.cluster_identifier
}

# RDS Proxyに割り当てるIAMロール
resource "aws_iam_role" "rds_proxy" {
  # IAMロール名
  name = "${var.project_name}-rds-proxy-role"
  # IAMロールに割り当てる信頼関係のポリシー
  assume_role_policy = data.aws_iam_policy_document.rds_proxy_assume.json
  # 説明
  description = "${var.project_name} RDS Proxy IAM Role"
  # タグ
  tags = {
    Name              = "${var.project_name}-aurora-postgresql"
    ProjectName       = var.project_name
    ResourceCreatedBy = "terraform"
  }
}
data "aws_iam_policy_document" "rds_proxy_assume" {
  statement {
    effect = "Allow"
    actions = [
      "sts:AssumeRole",
    ]
    principals {
      type = "Service"
      identifiers = [
        "rds.amazonaws.com",
      ]
    }
  }
}

# IAMロールに割り当てるIAMポリシー
resource "aws_iam_role_policy" "rds_proxy" {
  # IAMロールポリシー名
  name = "${var.project_name}-rds-proxy-policy"
  # IAMポリシー割り当て先のIAMロール
  role = aws_iam_role.rds_proxy.id
  # IAMポリシー
  policy = data.aws_iam_policy_document.rds_proxy_custom.json
}
data "aws_iam_policy_document" "rds_proxy_custom" {
  # Secrets Managerへのアクセスを許可
  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:GetResourcePolicy",
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
      "secretsmanager:ListSecretVersionIds"
    ]
    resources = [
      "arn:aws:secretsmanager:*:*:*",
    ]
  }
  # Key Management Serviceへのアクセスを許可
  statement {
    effect = "Allow"
    actions = [
      "kms:Decrypt",
    ]
    resources = [
      "*",
    ]
  }
}
