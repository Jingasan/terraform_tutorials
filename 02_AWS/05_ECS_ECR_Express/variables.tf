### グローバル変数の定義（terraform.tfvarsの変数値を受け取る）

# AWSのリージョン
variable "region" {}
# AWSアクセスキーのプロファイル
variable "profile" {}
# ドメイン名
variable "domain_name" {}
# コンテナ名
variable "container_name" {}
# コンテナイメージ名
variable "image_name" {}
# ビルドするコンテナイメージのDockerfileがあるディレクトリパス
variable "dockerfile_dir" {}
