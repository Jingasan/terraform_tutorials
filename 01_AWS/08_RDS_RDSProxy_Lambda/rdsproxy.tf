#============================================================
# RDS Proxy
#============================================================

# RDS Proxyに割り当てるIAMロール
resource "aws_iam_role" "rdsproxy" {
  # IAMロール名
  name = "${var.project_name}-rds-proxy-role"
  # IAMロールに割り当てる信頼関係のポリシー
  assume_role_policy = data.aws_iam_policy_document.rdsproxy_assume.json
  # 説明
  description = "${var.project_name} RDS Proxy IAM Role"
  # タグ
  tags = {
    Name = var.project_name
  }
}
data "aws_iam_policy_document" "rdsproxy_assume" {
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
resource "aws_iam_role_policy" "rdsproxy" {
  # IAMロールポリシー名
  name = "${var.project_name}-rds-proxy-policy"
  # IAMポリシー割り当て先のIAMロール
  role = aws_iam_role.rdsproxy.id
  # IAMポリシー
  policy = data.aws_iam_policy_document.rdsproxy_custom.json
}
data "aws_iam_policy_document" "rdsproxy_custom" {
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

# RDS Proxyの作成
resource "aws_db_proxy" "rdsproxy" {
  # エンジンファミリー
  engine_family = var.rds_proxy_engine_family
  # RDSへの接続を許可するIAMロールの指定
  role_arn = aws_iam_role.rdsproxy.arn
  # プロキシ識別子
  name = "${var.project_name}-${var.rds_engine}-proxy"
  # アプリケーションからののアイドル接続のタイムアウト（秒）（最小1分，最大8時間）
  idle_client_timeout = var.rds_proxy_idle_client_timeout
  # 認証の設定
  auth {
    # 認証方式の指定
    auth_scheme = "SECRETS"
    # Secrets ManagerのSecretのArn指定
    secret_arn = aws_secretsmanager_secret.rds.arn
    # クライアント認証タイプの指定
    client_password_auth_type = "POSTGRES_SCRAM_SHA_256"
    # IAM認証するかどうか
    iam_auth = "REQUIRED"
  }
  # TLS接続の有効化
  require_tls = true
  # VPCサブネットの指定
  vpc_subnet_ids = [for value in aws_subnet.private : value.id]
  # VPCセキュリティグループの指定
  vpc_security_group_ids = [aws_security_group.rds.id]
}

# ターゲットグループの設定
resource "aws_db_proxy_default_target_group" "rdsproxy" {
  # 設定の対象とするRDS Proxy名
  db_proxy_name = aws_db_proxy.rdsproxy.name
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
  db_proxy_name = aws_db_proxy.rdsproxy.name
  # 設定関連付け先のターゲットグループ名の指定
  target_group_name = aws_db_proxy_default_target_group.rdsproxy.name
  # RDS Proxyの対象とするRDSの指定
  db_instance_identifier = aws_db_instance.rds.identifier
}
