#==============================
# CloudWatch Logs
#==============================

# コンテナのログ保存先をCloudWatch Logsに作成
resource "aws_cloudwatch_log_group" "example" {
  # ロググループ名の設定
  name = "/ecs/nginx-loggroup"
  # タグ
  tags = {
    "Name" = "Terraform検証用"
  }
}
