#============================================================
# 環境変数の定義（terraform.tfvarsの変数値を受け取る）
#============================================================
# プロジェクト名
variable "project_name" {}
#============================================================
# Resource Group
#============================================================
# ロケーション
variable "location" {}
#============================================================
# ACR
#============================================================
# 価格プラン（Basic/Standard/Premium）
variable "acr_sku" {}
# コンテナイメージ名
variable "acr_image_name" {}
# ビルドするコンテナイメージのDockerfileがあるディレクトリパス
variable "acr_dockerfile_dir" {}
#============================================================
# Storage Account (Azure Batch用)
#============================================================
# 価格プラン (Standard/Premium)
variable "storage_account_tier" {}
# 冗長性 (LRS/GRS/RAGRS/ZRS/GZRS/RAGZRS)
variable "storage_account_replication_type" {}
