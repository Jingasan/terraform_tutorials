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
# Aurora
#============================================================
# Aurora DBのエンジン（aurora-mysql/aurora-postgresql）
variable "aurora_engine" {
  type        = string
  description = "Auroraのエンジン（aurora-mysql/aurora-postgresql）"
  default     = "aurora-postgresql"
}
# Aurora DBのエンジンのバージョン
variable "aurora_engine_version" {
  type        = string
  description = "Auroraのエンジンのバージョン"
  default     = "16.6"
}
# Aurora DBのエンジンモード（parallelquery/provisioned/serverless）
variable "aurora_engine_mode" {
  type        = string
  description = "Aurora DBのエンジンモード（parallelquery/provisioned/serverless）"
  default     = "provisioned"
}
# Aurora DBのポート番号
variable "aurora_port" {
  type        = number
  description = "Aurora DBのポート番号"
  default     = 5432
}
# Aurora DBの初期DB名
variable "aurora_database_name" {
  type        = string
  description = "Aurora DBの初期DB名"
  default     = "postgres"
}
# Aurora DBのマスターユーザー名
variable "aurora_master_username" {
  type        = string
  description = "Aurora DBのマスターユーザー名"
  default     = "postgres"
}
# Aurora DBのマスターパスワード
variable "aurora_master_password" {
  type        = string
  description = "Aurora DBのマスターパスワード"
  default     = "postgres"
}
# Aurora DBのインスタンスタイプ
variable "aurora_instance_class" {
  type        = string
  description = "Aurora DBのインスタンスタイプ"
  default     = "db.t4g.medium"
}
# Aurora DBインスタンスの最小数
variable "aurora_min_capacity" {
  type        = number
  description = "Aurora DBインスタンスの最小数"
  default     = 2
}
# Aurora DBインスタンスの最大数
variable "aurora_max_capacity" {
  type        = number
  description = "Aurora DBインスタンスの最大数"
  default     = 4
}
# AuroraのオートスケーリングにおけるCPU平均使用率の閾値（%）（この値を超えたらスケールアウトする）
variable "aurora_target_value" {
  type        = number
  description = "AuroraのオートスケーリングにおけるCPU平均使用率の閾値（%）（この値を超えたらスケールアウトする）"
  default     = 75.0
}
# スケールイン直後の再スケーリングを防ぐクールダウン時間（秒）（default:5分）
variable "aurora_scale_in_cooldown" {
  type        = number
  description = "スケールイン直後の再スケーリングを防ぐクールダウン時間（秒）（default:5分）"
  default     = 300
}
# スケールアウト直後の再スケーリングを防ぐクールダウン時間（秒）（default:5分）
variable "aurora_scale_out_cooldown" {
  type        = number
  description = "スケールアウト直後の再スケーリングを防ぐクールダウン時間（秒）（default:5分）"
  default     = 300
}
# CloudWatch Logsに出力するログの種類（指定しない場合は出力しない）
# Aurora PostgreSQLの場合はpostgresql（PostgreSQLの一般ログを出力する）を指定可能。
# （別途、PostgreSQL側でlog_statementなどのログ出力設定が必要だが、パラメータグループでも設定可能。）
# 尚、ログの出力過多はCloudWatch Logsのコスト増大の原因となる為、出力するログ種類の選定やキャッシュサーバー導入などの検討が必要。
variable "aurora_enabled_cloudwatch_logs_exports" {
  type        = list(string)
  description = "CloudWatch Logsに出力するログの種類（指定しない場合は出力しない）"
  default     = ["postgresql"]
}
# Aurora DBのメンテナンスを実施する時間帯（曜日+UTC時刻）
# preferred_backup_windowの時間帯と被らないこと。
variable "aurora_preferred_maintenance_window" {
  type        = string
  description = "Aurora DBのメンテナンスを実施する時間帯（曜日+UTC時刻）"
  default     = "sun:19:00-sun:22:00"
}
# Aurora DBのバックアップ保持期間（日）
variable "aurora_backup_retention_period" {
  type        = number
  description = "Aurora DBのバックアップ保持期間（日）"
  default     = 7
}
# Aurora DBのバックアップを実施する時間帯（UTC時刻）
# preferred_maintenance_windowの時間帯と被らないこと。
variable "aurora_preferred_backup_window" {
  type        = string
  description = "Aurora DBのバックアップを実施する時間帯（UTC時刻）"
  default     = "16:00-19:00"
}
# Auroraクラスターを削除時のバックアップ作成をスキップするかどうか（true:バックアップを作らずに削除する）
variable "aurora_skip_final_snapshot" {
  type        = bool
  description = "Auroraクラスターを削除する際にバックアップを作るかどうか（true:バックアップを作らずに削除する）"
  default     = false
}
# 削除保護（true:DBクラスターを削除できなくする（defaultはfalse））
# クラスターの削除保護が有効な状態で削除したい場合、まずクラスターの削除保護を解除すること。
variable "aurora_deletion_protection" {
  type        = bool
  description = "削除保護（true:DBクラスターを削除できなくする（defaultはfalse））"
  default     = true
}
# DBインスタンスの設定値の変更を即時反映するか（true:反映する/false(default):反映しない）
# 即時反映しない場合は次回のメンテナンスウィンドウで反映される。
variable "aurora_apply_immediately" {
  type        = bool
  description = "DBインスタンスの設定値の変更を即時反映するか（true:反映する/false(default):反映しない）"
  default     = false
}
# クラスターパラメータグループの適用先ファミリー
variable "aurora_cluster_parameter_group_family" {
  type        = string
  description = "クラスターパラメータグループの適用先ファミリー"
  default     = "aurora-postgresql16"
}
