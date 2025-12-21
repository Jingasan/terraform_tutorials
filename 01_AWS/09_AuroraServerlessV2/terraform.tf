#============================================================
# TerraformとProviderの設定
#============================================================

# Terraformの設定
terraform {
  # Terraformのバージョン指定(1.0以上2.0未満を使用)
  required_version = "~> 1.0"

  # .tfstateをS3で管理する設定
  # terraform initをする前に以下の保管用バケットをS3に作成しておく必要がある
  # backend "s3" {
  #   bucket = "terraform-tfstate-bucket" # .tfstateを保管するバケット名
  #   key    = "terraform.tfstate"        # 保管される.tfstateのファイル名
  #   region = "ap-northeast-1"           # バケットのリージョン
  # }
}

# プロバイダ設定
provider "aws" {
  region  = var.region  # AWSのリージョン
  profile = var.profile # AWSアクセスキーのプロファイル
}
