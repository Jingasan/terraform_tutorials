#============================================================
# TerraformとProviderの設定
#============================================================

# Terraformの設定
terraform {
  # Terraformのバージョン指定
  required_version = ">= 1.3.8"

  # Providerのバージョン指定
  required_providers {
    google = ">=5.4.0" # GoogleCloud
  }

  # .tfstateをGCS(Cloud Storage)で管理する設定
  # terraform initをする前に以下の保管用バケットをGCSに作成しておく必要がある
  # backend "gcs" {
  #   bucket = "terraform-tfstate-bucket" # .tfstateを保管するバケット名
  #   prefix = "tfstate"                  # default.tfstateファイルを保管するフォルダパス
  # }
}

# プロバイダ設定
provider "google" {
  region = var.region # デプロイ先のリージョン
}
