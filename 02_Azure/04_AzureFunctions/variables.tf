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
# Storage Account (Azure Functions用)
#============================================================
# 価格プラン (Standard/Premium)
variable "storage_account_tier" {}
# 冗長性 (LRS/GRS/RAGRS/ZRS/GZRS/RAGZRS)
variable "storage_account_replication_type" {}
#============================================================
# Azure Functions
#============================================================
# App Serviceの価格プラン (Y1/EP1/EP2/EP3/B1/B2/B3/S1/S2/S3/P1v2/P2v2/P3v2)
# https://azure.microsoft.com/ja-jp/pricing/details/app-service/linux/
variable "functions_sku_name" {}
# Azure FunctionsのNodeランタイムのバージョン
variable "functions_node_version" {}
