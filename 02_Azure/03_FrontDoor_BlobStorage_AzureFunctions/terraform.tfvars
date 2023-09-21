#============================================================
# 環境変数の定義
#============================================================
# プロジェクト名（英数字のみ）
project_name = "terraformtutorial"
#============================================================
# Blob Storage
#============================================================
# パフォーマンス (Standard/Premium)
account_storage_account_tier = "Standard"
# 冗長性 (LRS/GRS/RAGRS/ZRS/GZRS/RAGZRS)
account_storage_account_replication_type = "LRS"
#============================================================
# Azure Functions
#============================================================
# App Serviceの価格プラン (B1/B2/B3/S1/S2/S3/P1v2/P2v2/P3v2)
# https://azure.microsoft.com/ja-jp/pricing/details/app-service/linux/
functions_sku_name = "B1"
# Azure FunctionsのNodeランタイムのバージョン
functions_node_version = "18"