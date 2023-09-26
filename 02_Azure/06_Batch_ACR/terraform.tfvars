#============================================================
# 環境変数の定義
#============================================================
# プロジェクト名（英数字のみ）
project_name = "terraformtutorial"
#============================================================
# Resource Group
#============================================================
# ロケーション
location = "japaneast"
#============================================================
# ACR
#============================================================
# 価格プラン（Basic/Standard/Premium）
acr_sku = "Basic"
# コンテナイメージ名
acr_image_name = "ubuntu-echo"
# ビルドするコンテナイメージのDockerfileがあるディレクトリパス
acr_dockerfile_dir = "./batch/ubuntu-echo"
#============================================================
# Storage Account (Azure Batch用)
#============================================================
# 価格プラン (Standard/Premium)
storage_account_tier = "Standard"
# 冗長性 (LRS/GRS/RAGRS/ZRS/GZRS/RAGZRS)
storage_account_replication_type = "LRS"