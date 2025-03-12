#============================================================
# TerraformとProviderの設定
#============================================================

# Terraformの設定
terraform {
  # Terraformのバージョン指定
  required_version = ">= 1.11.0"

  # AWSのバージョン指定
  required_providers {
    aws = ">=5.90.0"
  }

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

# ランダムな小文字16進数値の生成
resource "random_id" "main" {
  byte_length = 2 # 値の範囲
}
locals {
  lower_random_hex = random_id.main.dec
}

# 現在のAWSアカウント情報
data "aws_caller_identity" "current" {}

# 現在のAWSリージョン情報
data "aws_region" "current" {}
