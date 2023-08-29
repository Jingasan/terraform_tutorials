### 変数の定義（terraform.tfvarsの変数値を受け取る）

# AWSのリージョン
variable "region" {}
# AWSアクセスキーのプロファイル
variable "profile" {}
# アップロード先のS3バケット名
variable "bucket_name" {}
# Webアプリのソースディレクトリ
variable "src_dir" {}
# Webサイトエンドポイント
variable "endpoint" {}
