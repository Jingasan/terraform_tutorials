#============================================================
# Cloud Storage
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
  public_access_prevention = "inherited"
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

# アクセス権の付与
# パブリックアクセスが許可されており、バケットレベルでの均一なアクセス制御が設定されている場合のみ有効
resource "google_storage_bucket_iam_binding" "binding" {
  # 対象バケット
  bucket = google_storage_bucket.bucket.name
  # プリンシパル(対象ユーザー)
  members = [
    "allUsers",
  ]
  # ロールの付与：オブジェクトの読み取りを許可
  # roles/storage.objectViewerでも良いが、バケットのオブジェクトの一覧も見れてしまう。
  # roles/storage.legacyObjectReaderは、オブジェクトの閲覧のみの最小限のロールである。
  role = "roles/storage.legacyObjectReader"
}

# オブジェクトのアップロード
resource "google_storage_bucket_object" "webpage" {
  # アップロード先のバケット
  bucket = google_storage_bucket.bucket.id
  # アップロード先のパス
  name = "index.html"
  # アップロード対象のファイルパス
  source = "webpage/index.html"
  # Content-Type
  content_type = "text/html"
}
