#============================================================
# WAF
#============================================================

# WAF用にプロバイダを追加
provider "aws" {
  alias  = "virginia"
  region = "us-east-1"
}

# IP Setの作成
resource "aws_wafv2_ip_set" "ipset" {
  # IP Setの名称
  name = "${var.project_name}-allow-ip-set"
  # IP Setの説明
  description = "${var.project_name} allow ip set"
  # IPアドレスのバージョン
  ip_address_version = "IPV4"
  # IP Setに含めるアドレス
  addresses = var.waf_allow_ips
  # IP Setのターゲット
  scope = "CLOUDFRONT"
  # scopeがCloudFrontの場合、バージニアリージョン(us-east-1)に作成する必要がある
  provider = aws.virginia
  # タグ
  tags = {
    Name = var.project_name
  }
}

# WebACLの作成
resource "aws_wafv2_web_acl" "web_acl" {
  # WebACL名
  name = "${var.project_name}-web-acl"
  # WebACLの説明
  description = "${var.project_name} Web ACL that blocks all traffic except for allow IP set"
  # デフォルトアクション
  default_action {
    # すべてのアクセスを拒否
    block {}
  }
  # ルール
  rule {
    # ルール名
    name = "${var.project_name}-allow-ip-set"
    # ルールの優先度
    priority = 1
    # アクション
    action {
      # ルールを満たすアクセスを許可
      allow {}
    }
    # ルールの設定
    statement {
      # IP Setの指定
      ip_set_reference_statement {
        arn = aws_wafv2_ip_set.ipset.arn
      }
    }
    # CloudWatchメトリクスの設定
    visibility_config {
      metric_name                = "${var.project_name}-web-acl-rule-metric"
      cloudwatch_metrics_enabled = false
      sampled_requests_enabled   = false
    }
  }
  # CloudWatchメトリクスの設定
  visibility_config {
    metric_name                = "${var.project_name}-web-acl-metric"
    cloudwatch_metrics_enabled = false
    sampled_requests_enabled   = false
  }
  # WebACLのターゲット
  scope = "CLOUDFRONT"
  # scopeがCloudFrontの場合、バージニアリージョン(us-east-1)に作成する必要がある
  provider = aws.virginia
  # タグ
  tags = {
    Name = var.project_name
  }
}
