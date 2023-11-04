#============================================================
# Cloud Storage - プライベートなバケットの作成
#============================================================

# バケットの作成
resource "google_storage_bucket" "bucket" {
  # バケット名
  name = var.project_id
  # プロジェクトID
  project = var.project_id
  # ロケーション
  location = var.region
  # ストレージクラス
  storage_class = var.cloud_storage_storage_class
  # パブリックアクセスの防止(enforced:パブリックアクセスを防止(default)/inherited:パブリックアクセスを許可)
  public_access_prevention = "enforced"
  # アクセス制御の設定(true:バケットレベルでの均一なアクセス制御(default)/false:オブジェクトレベル(ACL)でのアクセス制御)
  uniform_bucket_level_access = true
  # オブジェクトのバージョニング(false:バージョン管理しない(default)/true:バージョン管理する)
  versioning {
    enabled = false
  }
  # CORSの設定
  cors {
    origin          = ["*"]
    method          = ["GET", "HEAD", "PUT", "POST", "DELETE"]
    response_header = ["*"]
    max_age_seconds = 3600
  }
  # ライフサイクルルールの設定(1日以上かかっているマルチパートアップロードをAbortする)
  lifecycle_rule {
    condition {
      age = 1
    }
    action {
      type = "AbortIncompleteMultipartUpload"
    }
  }
  # バケットの中にオブジェクトが入っていてもTerraformに削除を許可するかどうか(true:許可)
  force_destroy = true
  # ラベル
  labels = {
    name = var.project_id
  }
}
