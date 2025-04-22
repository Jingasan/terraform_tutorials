#============================================================
# 環境変数の定義
#============================================================
# プロジェクト名（小文字英数字かハイフンのみ有効）
# プロジェクト毎に他のプロジェクトと被らないユニークな名前を指定すること
variable "project_name" {
  type        = string
  description = "プロジェクト名（リソースの名前、タグ、説明文に利用される）"
  default     = "terraform-tutorials"
}
#============================================================
# AWS Provider
#============================================================
# AWSのリージョン
variable "region" {
  type        = string
  description = "AWSのリージョン"
  default     = "ap-northeast-1"
}
# AWSアクセスキーのプロファイル
variable "profile" {
  type        = string
  description = "AWSアクセスキーのプロファイル"
  default     = "default"
}
#============================================================
# Network
#============================================================
# VPC CIDR
variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR"
  default     = "10.0.0.0/16"
}
#============================================================
# ElastiCache
#============================================================
# エンジン（valkey/redis）
variable "elasticache_engine" {
  type        = string
  description = "エンジン（valkey/redis）"
  default     = "valkey"
}
# エンジンのバージョン
variable "elasticache_engine_version" {
  type        = string
  description = "エンジンのバージョン"
  default     = "8.0"
}
# ノードタイプ（最小インスタンスの場合:cache.t2.micro）
variable "elasticache_node_type" {
  type        = string
  description = "ノードタイプ"
  default     = "cache.m6g.large"
}
# クラスターに割り当てるパラメータグループ名
variable "elasticache_parameter_group_name" {
  type        = string
  description = "クラスターに割り当てるパラメータグループ名"
  default     = "default.valkey8.cluster.on"
}
# Valkeyのポート番号
variable "elasticache_port" {
  type        = number
  description = "Valkeyのポート番号"
  default     = 6379
}
# 最小シャード数（1-500個の値を指定）
variable "elasticache_min_capacity" {
  type        = number
  description = "最小シャード数（1-500個の値を指定）"
  default     = 1
}
# 最大シャード数（1-500の値を指定）
variable "elasticache_max_capacity" {
  type        = number
  description = "最大シャード数（1-500の値を指定）"
  default     = 2
}
# レプリカ数（0-5個の値を指定）
variable "elasticache_replicas_per_node_group" {
  type        = number
  description = "レプリカ数（0-5個の値を指定）"
  default     = 1
}
# 接続パスワード（16-128文字で指定）
variable "elasticache_auth_token" {
  type        = string
  description = "接続パスワード（16-128文字で指定）"
  default     = "default_user_password"
}
# バックアップ保持期間（日）
variable "elasticache_snapshot_retention_limit" {
  type        = number
  description = "バックアップ保持期間（日）"
  default     = 1
}
# バックアップ時間（UTCの形式で指定）
variable "elasticache_snapshot_window" {
  type        = string
  description = "バックアップ時間（UTC）"
  default     = "00:00-01:00"
}
# メンテナンス期間（曜日:UTCの形式で指定）
variable "elasticache_maintenance_window" {
  type        = string
  description = "メンテナンス期間（曜日:UTCの形式で指定）"
  default     = "tue:03:00-tue:04:00"
}
# マイナーバージョンの自動アップグレード
variable "elasticache_auto_minor_version_upgrade" {
  type        = string
  description = "マイナーバージョンの自動アップグレード"
  default     = "true"
}
# ElastiCacheクラスターの設定値の変更を即時反映するか（true:反映する/false(default):反映しない）
# 即時反映しない場合は次回のメンテナンスウィンドウで反映される。
variable "elasticache_apply_immediately" {
  type        = bool
  description = "ElastiCacheクラスターの設定値の変更を即時反映するか（true:反映する/false(default):反映しない）"
  default     = false
}
