#============================================================
# 環境変数の定義（terraform.tfvarsの変数値を受け取る）
#============================================================
# プロジェクトID
variable "project_id" {}
# リージョン
variable "region" {}
#============================================================
# Compute Engine
#============================================================
# ゾーン
variable "gce_zone" {}
# OSイメージ
variable "gce_image" {}
# マシンタイプ(インスタンスのvCPU数/メモリサイズの設定)
variable "gce_machine_type" {}
# ディスクサイズ(GB)(10-65536GBの範囲で指定)
variable "gce_size" {}
# SSH接続を許可するユーザー
variable "gce_allow_ssh_user" {}