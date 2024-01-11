#============================================================
# Cloud Functions
#============================================================

# 関数コード用バケットの作成
data "google_project" "project" {}
resource "google_storage_bucket" "gcf" {
  depends_on = [google_project_service.apis]
  # バケット名
  name = "gcf-v2-sources-${data.google_project.project.number}-${var.region}"
  # プロジェクトID
  project = var.project_id
  # ロケーション
  location = var.region
  # ストレージクラス
  storage_class = var.gcs_storage_class
  # パブリックアクセスの防止(enforced:パブリックアクセスを防止(default)/inherited:パブリックアクセスを許可)
  public_access_prevention = "enforced"
  # アクセス制御の設定(true:バケットレベルでの均一なアクセス制御(default)/false:オブジェクトレベル(ACL)でのアクセス制御)
  uniform_bucket_level_access = true
  # オブジェクトのバージョニング(false:バージョン管理しない(default)/true:バージョン管理する)
  versioning {
    enabled = false
  }
  # バケットの中にオブジェクトが入っていてもTerraformに削除を許可するかどうか(true:許可)
  force_destroy = true
  # ラベル
  labels = {
    name = var.project_id
  }
}

# 関数のZIP圧縮
data "archive_file" "gcf" {
  # 圧縮タイプ：ZIP圧縮を指定
  type = "zip"
  # 関数のプロジェクトのディレクトリパス
  source_dir = "api"
  # 圧縮ファイルの出力先
  output_path = "cloudfunctions.zip"
}

# ZIP圧縮した関数のGCSアップロード
resource "google_storage_bucket_object" "object" {
  depends_on = [google_project_service.apis]
  # アップロード先のオブジェクトパス
  name = "cloudfunctions.${data.archive_file.gcf.output_md5}.zip"
  # アップロード先のバケット
  bucket = google_storage_bucket.gcf.name
  # アップロードするファイルのパス
  source = data.archive_file.gcf.output_path
}

# Cloud Functions関数の作成
resource "google_cloudfunctions2_function" "gcf" {
  depends_on = [google_project_service.apis]
  # 関数名
  name = var.project_id
  # ロケーション
  location = var.region
  # ビルド設定
  build_config {
    # ランタイム
    runtime = var.gcf_runtime
    # エントリーポイント
    entry_point = "api"
    source {
      # 関数が配置されたGCSのバケット名とオブジェクトパスの指定
      storage_source {
        bucket = google_storage_bucket.gcf.name
        object = google_storage_bucket_object.object.name
      }
    }
    # ビルド時の環境変数
    environment_variables = {
    }
  }
  # サービス設定
  service_config {
    # 最大vCPU数 default:最大メモリ量から算出される
    available_cpu = var.gcf_available_cpu
    # 最大メモリ量 default:256M
    available_memory = var.gcf_available_memory
    # 関数のタイムアウト時間[sec] default:60
    timeout_seconds = var.gcf_timeout_seconds
    # 最大インスタンス数 default:100
    max_instance_count = var.gcf_max_instance_count
    # 最小インスタンス数 default:0
    min_instance_count = var.gcf_min_instance_count
    # インスタンスあたりの最大同時リクエスト数 default:1
    max_instance_request_concurrency = var.gcf_max_instance_request_concurrency
    # 関数実行時の環境変数
    environment_variables = {
      "BUCKET"      = google_storage_bucket.bucket.name
      "CREDENTIALS" = base64decode(google_service_account_key.key.private_key)
    }
  }
  # 関数の説明文
  description = var.project_id
  # ラベル
  labels = {
    name = var.project_id
  }
}

# CloudFunctions(実体はCloudRun)に対してIAMポリシーを割り当て
# すべてのユーザーが認証なし(Authorizationヘッダーなし)でAPIを実行できるようにする
resource "google_cloud_run_service_iam_member" "gcf" {
  depends_on = [google_project_service.apis]
  # 割り当て先のリソース
  service = google_cloudfunctions2_function.gcf.name
  # リソースのロケーション
  location = google_cloudfunctions2_function.gcf.location
  # ロールを割り当てる対象ユーザー：すべてのユーザー
  member = "allUsers"
  # 割り当てるロール：実行権限
  role = "roles/run.invoker"
}

# Cloud Functions API URLの表示
output "function_uri" {
  description = "Cloud Functions API URL"
  value       = google_cloudfunctions2_function.gcf.service_config[0].uri
}
