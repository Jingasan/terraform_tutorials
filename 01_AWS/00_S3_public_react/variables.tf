### グローバル変数の定義（terraform.tfvarsの変数値を受け取る）

# アップロード先のS3バケット名
variable "bucket_name" {}
# Webアプリのソースディレクトリ
variable "src_dir" {}
# アップロード対象のディレクトリ
variable "upload_dir" {}
# アップロード先のS3バケットディレクトリパス
variable "dist_s3dir" {}
# WebアプリトップページのS3パス
variable "toppage_s3key" {}
# タグ名
variable "tag_name" {}
