#==============================
# DynamoDB
#==============================

# DynamoDBの作成
resource "aws_dynamodb_table" "example" {
  # DynamoDBのリソース名
  name = "example"
  # キャパシティユニット(1秒あたりに読み書きできる上限回数)の設定
  read_capacity  = 5
  write_capacity = 5
  # パーティションキーの設定
  hash_key = "id"
  # ソートキーの設定
  range_key = "title"
  # hash_keyとrange_keyのtypeの指定(S:文字, N:数値, B:バイナリデータ)
  attribute {
    name = "id"
    type = "S"
  }
  attribute {
    name = "title"
    type = "S"
  }
  # タグ
  tags = {
    Name = "Terraform検証用"
  }
}
