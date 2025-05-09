#============================================================
# Terraform 基本設定
#============================================================
terraform {
  # Terraformのバージョン指定(1.0以上2.0未満を使用)
  required_version = "~> 1.0"

  # AWSプロバイダのバージョン指定(5.0以上6.0未満を使用)
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }

  # .tfstateをS3で管理する設定
  # terraform initをする前に以下の保管用バケットをS3に作成しておく必要がある
  # backend "s3" {
  #   bucket = "terraform-tfstate-bucket" # .tfstateを保管するバケット名
  #   key    = "terraform.tfstate"        # 保管される.tfstateのファイル名
  #   region = "ap-northeast-1"           # バケットのリージョン
  # }
}



#============================================================
# クラウドプロバイダの設定
#============================================================

# デフォルトプロバイダ
provider "aws" {
  # メインリソース群の作成先リージョン
  region = var.region
  # AWSアクセスキーのプロファイル
  profile = var.profile
  # デフォルトのタグ
  default_tags {
    # タグ
    tags = {
      Name              = var.project_name
      ProjectName       = var.project_name
      ProjectStage      = local.project_stage
      ResourceCreatedBy = "terraform"
    }
  }
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
