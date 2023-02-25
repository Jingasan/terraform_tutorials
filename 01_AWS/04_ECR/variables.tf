### グローバル変数の定義（terraform.tfvarsの環境変数値を受け取る）

# AWSのリージョン
variable "region" {}
# AWSアクセスキーのプロファイル
variable "profile" {}
# コンテナイメージ名
variable "image_name" {}
# ビルドするコンテナイメージのDockerfileがあるディレクトリパス
variable "dockerfile_dir" {}
