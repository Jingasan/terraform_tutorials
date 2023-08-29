# Terraformの設定
terraform {
  # Terraformのバージョン指定
  required_version = ">= 1.3.8"

  # AWSのバージョン指定
  required_providers {
    aws = ">=4.53.0"
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
  profile = var.profile # AWS CLI Profile

  s3_use_path_style           = true
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  skip_region_validation      = true

  # AWSサービスエンドポイントの設定
  endpoints {
    s3 = var.s3_endpoint # S3のエンドポイントにローカルのMinIOを指定
  }
}

#============================================================
# S3
#============================================================

# バケット名とタグの設定
resource "aws_s3_bucket" "main" {
  bucket = var.bucket_name

  # バケットの中にオブジェクトが入っていてもTerraformに削除を許可するかどうか(true:許可)
  force_destroy = true

  # タグ
  tags = {
    Name = var.tag_name
  }
}

# バケットポリシー
resource "aws_s3_bucket_policy" "main" {
  bucket = aws_s3_bucket.main.id
  # CloudFront Distributionからのアクセスのみ許可するポリシーを追加
  policy = data.aws_iam_policy_document.s3_main_policy.json
}
# CloudFront Distributionからのアクセスのみ許可するポリシー
data "aws_iam_policy_document" "s3_main_policy" {
  statement {
    sid    = "0"
    effect = "Allow"
    # アクセス元の設定
    principals {
      type        = "*"
      identifiers = ["*"] # 誰でもアクセスを許可
    }
    # バケットに対して制御するアクションの設定
    actions = ["s3:GetObject"]
    # アクセス先の設定
    resources = [
      "${aws_s3_bucket.main.arn}",  # S3バケットへのアクセス。
      "${aws_s3_bucket.main.arn}/*" # S3バケット配下へのアクセス。
    ]
  }
}


# オブジェクトのバージョン管理の設定
resource "aws_s3_bucket_versioning" "main" {
  bucket = aws_s3_bucket.main.id
  versioning_configuration {
    status = "Enabled"
  }
}

# 外部コマンドの実行
locals {
  src_dir = "./webpage"                         # アップロード対象のディレクトリ
  dst_dir = "s3://${aws_s3_bucket.main.bucket}" # アップロード先
}
resource "null_resource" "fileupload" {
  # S3バケット作成完了後に実行
  triggers = {
    trigger = "${aws_s3_bucket.main.id}"
  }

  # ローカルディレクトリにあるWebページをS3バケットにアップロード
  provisioner "local-exec" {
    command = "aws --endpoint-url ${var.s3_endpoint} --profile ${var.profile} s3 cp ${local.src_dir} ${local.dst_dir} --recursive"
  }
}

# WebアプリトップページURLのコンソール出力
output "toppage_url" {
  description = "Top Page URL"
  value       = "${var.s3_endpoint}/${aws_s3_bucket.main.bucket}/index.html"
}
