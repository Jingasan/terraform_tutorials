#============================================================
# Cloud Run Service
#============================================================

# サービスの作成
resource "google_cloud_run_v2_service" "service" {
  depends_on = [google_project_service.apis, google_artifact_registry_repository.docker]
  # サービス名
  name = var.project_id
  # ロケーション
  location = var.region
  # Ingressの制御
  # INGRESS_TRAFFIC_ALL: インターネットからサービスに直接アクセスを許容
  # INGRESS_TRAFFIC_INTERNAL_ONLY: プロジェクト内からのアクセスのみを許容
  # INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER: プロジェクト内のロードバランサ―からのアクセスのみを許容
  ingress = "INGRESS_TRAFFIC_ALL"
  # コンテナイメージ
  template {
    containers {
      # コンテナ名
      name = var.gar_image_name
      # リポジトリのイメージURL
      image = local.image_url
      # プロトコルとポート番号
      ports {
        # プロトコル(http1/h2c)
        name = "http1"
        # コンテナのポート番号
        container_port = 3000
      }
      # リソース関連の設定
      resources {
        limits = {
          # vCPUコア数上限
          cpu = "1"
          # メモリサイズ上限
          memory = "512Mi"
        }
        # CPU割り当て設定 true(default):リクエスト処理中のみCPUを割り当てる/false:常時CPUを割り当てる
        cpu_idle = true
        # 起動時のCPUブースト true(default): 起動時には多くのCPUを割り当ててコンテナの起動を高速化する
        startup_cpu_boost = true
      }
      # コンテナ起動時のコマンド
      command = []
      # コンテナ起動時の引数
      args = []
      # 環境変数
      env {
        name  = "ENV_NAME"
        value = "ENV_VALUE"
      }
    }
    # インスタンスあたりの最大同時リクエスト数
    max_instance_request_concurrency = 80
    # リクエストタイムアウト(秒)
    timeout = "300s"
    # 実行環境(EXECUTION_ENVIRONMENT_GEN2:第2世代/EXECUTION_ENVIRONMENT_GEN2:第1世代)
    execution_environment = "EXECUTION_ENVIRONMENT_GEN2"
    # セッションアフィニティ
    # true:同一クライアントからのリクエストを可能な限り同一コンテナにルーティング/false(default)
    session_affinity = false
    scaling {
      min_instance_count = 0
      max_instance_count = 100
    }
    # ラベル
    labels = {
      name = var.project_id
    }
    # アノテーション
    annotations = {
      name = var.project_id
    }
  }
  # 説明文
  description = var.project_id
  # ラベル
  labels = {
    name = var.project_id
  }
  # アノテーション
  annotations = {
    name = var.project_id
  }
}

# CloudRunに対してIAMポリシーを割り当て
# すべてのユーザーが認証なし(Authorizationヘッダーなし)でサービスURLを実行できるようにする
resource "google_cloud_run_v2_service_iam_member" "member" {
  # 割り当て先のサービス名
  name = google_cloud_run_v2_service.service.name
  # ロケーション
  location = google_cloud_run_v2_service.service.location
  # ロールを割り当てる対象ユーザー：すべてのユーザー
  member = "allUsers"
  # 割り当てるロール：実行権限
  role = "roles/run.invoker"
}

# サービスのURL表示
output "service_url" {
  description = "Service URL"
  value       = google_cloud_run_v2_service.service.uri
}
