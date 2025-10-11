#============================================================
# 環境変数の定義（terraform.tfvarsの変数値を受け取る）
#============================================================
# プロジェクト名
variable "project_name" {}
#============================================================
# AWS Account
#============================================================
# AWSのリージョン
variable "region" {}
# AWSアクセスキーのプロファイル
variable "profile" {}
#============================================================
# Network
#============================================================
# VPC CIDR
variable "vpc_cidr" {}
# パブリックサブネット CIDRS
variable "public_subnet_cidrs" {}
# プライベートサブネット CIDRS
variable "private_subnet_cidrs" {}
#============================================================
# ECR
#============================================================
# コンテナイメージ名
variable "ecr_docker_image_name" {}
#============================================================
# Batch
#============================================================
# コンピューティング環境 - 最大vCPU数（ジョブの同時実行数=最大vCPU数/ジョブ1つのvCPU数）
variable "batch_max_vcpus" {}
# CloudWatchにログを残す期間（日）
variable "batch_cloudwatch_log_retention_in_days" {}
# コンテナに渡すコマンド
variable "batch_commands" {}
# vCPU数
variable "batch_vcpu" {}
# メモリサイズ(MB)
variable "batch_memory" {}
#============================================================
# Lambda
#============================================================
# 実行ランタイム（ex: nodejs, python, go, etc.）
variable "lambda_runtime" {}
# Lambda関数のタイムアウト時間
variable "lambda_timeout" {}
# CloudWatchにログを残す期間（日）
variable "lambda_cloudwatch_log_retention_in_days" {}
