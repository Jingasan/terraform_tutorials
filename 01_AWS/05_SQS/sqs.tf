#==============================
# SQS
#==============================

# SQSメッセージキューの作成
resource "aws_sqs_queue" "example" {
  # メッセージキューの名前
  name = "example.fifo"
  # FIFOキューにするかどうか
  fifo_queue = true
  # メッセージの最大サイズ
  max_message_size = 2048
  # メッセージの保持期間[s]
  message_retention_seconds = 1 * 24 * 60 * 60
  # コンテンツベースの重複排除の有効化設定
  content_based_deduplication = true
  # タグ
  tags = {
    Name = "Terraform検証用"
  }
}
