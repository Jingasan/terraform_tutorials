#============================================================
# TerraformとProviderの設定
#============================================================

# Terraformの設定
terraform {
  # Terraformのバージョン指定
  required_version = ">= 1.11.0"

  # AWSのバージョン指定
  required_providers {
    aws = ">=5.92.0"
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

# バックアップの複製先リージョンのプロバイダ設定
provider "aws" {
  alias   = "backup_clone_region"
  region  = var.backup_clone_region # バックアップの複製先リージョン（バックアップの複製元とは別リージョンを指定すること）
  profile = var.profile             # AWSアクセスキーのプロファイル
}

# ランダムな小文字16進数値の生成
resource "random_id" "main" {
  byte_length = 2 # 値の範囲
}
# プロジェクトのステージ名（例：dev/prod/test/個人名）
locals {
  # var.project_nameでステージ名が指定されてなければ、ランダムな整数値を指定
  project_stage = var.project_stage != null ? var.project_stage : random_id.main.dec
}

# 現在のAWSアカウント情報
data "aws_caller_identity" "current" {}

# 現在のAWSリージョン情報
data "aws_region" "current" {}
