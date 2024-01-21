#============================================================
# 環境変数の定義（terraform.tfvarsの変数値を受け取る）
#============================================================
# プロジェクトID
variable "project_id" {}
# リージョン
variable "region" {}
#============================================================
# Certificate Manager
#============================================================
# ドメイン(事前にCloudDomainsで取得しておく)
variable "certificate_manager_domain" {}
#============================================================
# Compute Engine
#============================================================
# ゾーン
variable "gce_zone" {}
# OSイメージ
variable "gce_image" {}
# マシンタイプ(インスタンスのvCPU数/メモリサイズの設定)
variable "gce_machine_type" {}
# ブートディスクの種類
# pd-balanced：バランス永続ディスク
# pd-extremeエクストリーム永続ディスク
# pd-ssd：SSD永続ディスク
# pd-standard：標準永続ディスク
variable "gce_type" {}
# ディスクサイズ(GB)(10-65536GBの範囲で指定)
variable "gce_size" {}
# VMプロビジョニングモデル(STANDARD/SPOT)
variable "gce_provisioning_model" {}
# ネットワークサービスのプラン
# STANDARD:単一リージョン内で閉じたサービス向け, PREMIUMよりも安価
# PREMIUM(default):グローバルな可用性を必要とするサービス向け
# https://cloud.google.com/network-tiers/docs/overview
variable "gce_network_tier" {}
# SSH接続を許可するユーザー
variable "gce_allow_ssh_user" {}
