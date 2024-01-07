#============================================================
# Cloud SQL
#============================================================

# SQLインスタンスの作成
resource "google_sql_database_instance" "default" {
  depends_on = [google_project_service.apis, google_service_networking_connection.default]
  # インスタンスID
  name = var.project_id
  # データベースのバージョン
  database_version = var.sql_database_version
  # ルートパスワード
  root_password = var.sql_root_password
  # リージョン
  region = var.region
  # SQLインスタンスの削除の禁止(true:削除を禁止/false:削除を許可)
  deletion_protection = false
  # 詳細設定
  settings {
    # Cloud SQLのエディション選択
    edition = var.sql_edition
    # 料金プラン:従量課金(PER_USE)のみ選択可能
    pricing_plan = "PER_USE"
    # ゾーンの可用性(ZONAL:シングルゾーン/REGIONAL:複数のゾーン)
    availability_type = var.sql_availability_type
    # プライマリゾーン
    location_preference {
      zone = var.sql_zone
    }
    # マシンの構成
    tier = var.sql_tier
    # ストレージの種類(PD_SSD(default)(推奨)/PD_HDD)
    disk_type = var.sql_disk_type
    # ストレージ容量(GB)
    disk_size = var.sql_disk_size
    # ストレージの自動増量の有効化(true:有効)
    disk_autoresize = var.sql_disk_autoresize
    # 自動増量の最大サイズ(GB)
    disk_autoresize_limit = var.sql_disk_autoresize_limit
    # 接続の設定
    ip_configuration {
      # IPv4アドレスの有効化(true:有効)
      ipv4_enabled = false
      # CloudSQLのプライベートIPにアクセスするVPCの指定
      private_network = google_compute_network.vpc.id
    }
    # バックアップ設定
    backup_configuration {
      # バックアップの有効化(true:有効/false:無効)
      enabled = true
      # バックアップ先の地域
      location = "asia"
      # 日次バックアップの設定
      backup_retention_settings {
        # バックアップ数
        retained_backups = var.sql_retained_backups
        # 単位:数(COUNT)のみ利用可能
        retention_unit = "COUNT"
      }
      # バックアップの開始時間(バックアップは開始時間から最大4時間)
      start_time = var.sql_backup_start_time
      # ログの日数(日)
      transaction_log_retention_days = var.sql_transaction_log_retention_days
      # バイナリロギングの有効化(MySQLでのみ利用可能)(true:有効/false:無効)
      binary_log_enabled = false
    }
    # SQLインスタンスの削除の禁止(true:削除を禁止/false:削除を許可)
    deletion_protection_enabled = false
    # Query Insightsの設定
    insights_config {
      # クエリ分析情報を有効化(true:有効)
      query_insights_enabled = false
      # クライアントIPアドレスの保存(true:保存)
      record_client_address = false
      # アプリケーションタグの保存(true:保存)
      record_application_tags = false
      # クエリの長さ(256-4500byte, default:1024)
      query_string_length = 256
      # 最大サンプリングレート(0-20/分, default:5, 0:サンプリング無効)
      query_plans_per_minute = 0
    }
    # メンテナンスの設定
    maintenance_window {
      # メンテナンス日(1:月,2:火,3:水,4:木,5:金,6:土,7:日)
      day = var.sql_maintenance_day
      # メンテナンス開始時間(0-23時)
      hour = var.sql_maintenance_start_hour
    }
    # パスワードポリシー
    password_validation_policy {
      # パスワードポリシーの有効化(true:有効)
      enable_password_policy = true
      # パスワードの許容する最小の長さ
      min_length = 8
      # パスワードに英大文字, 英小文字, 数字, 記号を含めることを要求
      complexity = "COMPLEXITY_DEFAULT"
      # パスワードにユーザー名を許容しない(true:許容しない)
      disallow_username_substring = true
      # パスワード再利用の制限(0:制限しない, 0以上:指定した回数以上他のパスワードの設定を必要とする)
      reuse_interval = 0
    }
    # タグ
    user_labels = {
      name = var.project_id
    }
  }
}

# ユーザー作成
resource "google_sql_user" "users" {
  depends_on = [google_project_service.apis]
  # ユーザー作成の対象となるSQLインスタンス
  instance = google_sql_database_instance.default.name
  # ユーザー名
  name = var.sql_username
  # ユーザーパスワード
  password = var.sql_userpassword
}

# データベースの作成
resource "google_sql_database" "database" {
  depends_on = [google_project_service.apis]
  # データベース作成の対象となるSQLインスタンス
  instance = google_sql_database_instance.default.name
  # データベース名
  name = var.sql_databasename
}
