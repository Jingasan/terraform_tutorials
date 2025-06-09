#============================================================
# TerraformとProviderの設定
#============================================================

# Terraformの設定
terraform {
  # Terraformのバージョン指定
  required_version = ">= 1.11.4"

  # AWSのバージョン指定
  required_providers {
    aws = ">=5.99.0"
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
  # AWSのリージョン
  region = var.aws_region
  # AWSアクセスキーのプロファイル
  profile = var.aws_profile
  # デフォルトのタグ
  default_tags {
    # タグ
    tags = {
      Name              = var.project_name
      ProjectName       = var.project_name
      ResourceCreatedBy = "terraform"
    }
  }
}

# バックアップ複製先用にプロバイダを追加
provider "aws" {
  # プロバイダ名称
  alias = "s3_replication_region"
  # バックアップ複製先リージョン
  region = var.s3_replication_region
  # AWSアクセスキーのプロファイル
  profile = var.aws_profile
  # デフォルトのタグ
  default_tags {
    # タグ
    tags = {
      Name              = var.project_name
      ProjectName       = var.project_name
      ResourceCreatedBy = "terraform"
    }
  }
}

# ランダムな小文字16進数値の生成
resource "random_id" "main" {
  byte_length = 2 # 値の範囲
}
locals {
  lower_random_hex = random_id.main.dec
}
