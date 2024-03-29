#============================================================
# 環境変数の定義（terraform.tfvarsの変数値を受け取る）
#============================================================
# プロジェクトID
variable "project_id" {}
# リージョン
variable "region" {}
# ドメイン (Google Domainsで取得したドメインを指定する)
variable "domain" {}
