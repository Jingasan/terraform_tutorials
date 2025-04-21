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
# ElastiCacheのエンジン（valkey/redis/memcached）
variable "elasticache_engine" {
  type        = string
  description = "ElastiCacheのエンジン（valkey/redis/memcached）"
  default     = "memcached"
}
# ElastiCacheのエンジンのバージョン
variable "elasticache_engine_version" {
  type        = string
  description = "ElastiCacheのエンジンのバージョン"
  default     = "1.6.22"
}
# ノードタイプ
variable "elasticache_node_type" {
  type        = string
  description = "ノードタイプ"
  default     = "cache.t4g.micro"
}
# クラスターに割り当てるパラメータグループ名
variable "elasticache_parameter_group_name" {
  type        = string
  description = "クラスターに割り当てるパラメータグループ名"
  default     = "default.memcached1.6"
}
# Memcachedのポート番号
variable "elasticache_port" {
  type        = number
  description = "Memcachedのポート番号"
  default     = 11211
}
# ノードを複数のAZに作成するかどうか（single-az(default):単一AZ／cross-az:複数AZ）
# cross-azを指定する場合、num_cache_nodesの値は2以上である必要がある。
variable "elasticache_az_mode" {
  type        = string
  description = "ノードを複数のAZに作成するかどうか（single-az(default):単一AZ／cross-az:複数AZ）"
  default     = "cross-az"
}
# ElastiCacheクラスターの設定値の変更を即時反映するか(true:即時反映する)
# 即時反映しない場合は次回のメンテナンスウィンドウで反映される。
variable "elasticache_apply_immediately" {
  type        = bool
  description = "value"
  default     = false
}
# ElastiCacheノードの数
variable "elasticache_num_cache_nodes" {
  type        = number
  description = "ElastiCacheノードの最小数"
  default     = 2
}
