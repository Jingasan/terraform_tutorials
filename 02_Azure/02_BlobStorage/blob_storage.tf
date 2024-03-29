#============================================================
# Blob Storage
#============================================================

# ランダムな小文字16進数値の生成
resource "random_id" "blob" {
  byte_length = 2 # 値の範囲
}
locals {
  lower_random_hex = random_id.blob.dec
}

# ストレージアカウントの作成
resource "azurerm_storage_account" "blob" {
  depends_on = [random_id.blob]
  # 所属させるリソースグループ
  resource_group_name = azurerm_resource_group.rg.name
  # ストレージアカウント名
  name = "${var.project_name}${local.lower_random_hex}"
  # 作成先のリージョン
  location = azurerm_resource_group.rg.location
  # アカウントの種類
  account_kind = "StorageV2"
  # パフォーマンス (Standard/Premium)
  account_tier = var.storage_account_tier
  # 冗長性 (LRS/GRS/RAGRS/ZRS/GZRS/RAGZRS)
  account_replication_type = var.storage_account_replication_type
  # REST API操作の安全な転送を有効化
  enable_https_traffic_only = true
  # 個々のコンテナでの匿名アクセスの有効化（内部のデータをWeb公開するかどうか）
  allow_nested_items_to_be_public = true
  # ストレージアカウントキーへのアクセスの有効化
  shared_access_key_enabled = true
  # TLSの最小バージョン
  min_tls_version = "TLS1_2"
  # アクセス層 (Hot/Cool)
  access_tier = "Hot"
  # ネットワークアクセス
  network_rules {
    bypass = [
      "AzureServices",
    ]
    # すべてのネットワークからのパブリックアクセスを有効化
    default_action             = "Allow"
    ip_rules                   = []
    virtual_network_subnet_ids = []
  }
  blob_properties {
    # BLOBの論理的な削除を有効化
    delete_retention_policy {
      # 削除されたBLOBを保持する日数
      days = 7
    }
    # コンテナの論理的な削除を有効化
    container_delete_retention_policy {
      # 削除されたコンテナを保持する日数
      days = 7
    }
    # BLOBのバージョン管理の有効化
    versioning_enabled = false
    # BLOBの変更フィードの有効化
    change_feed_enabled = false
  }
  # ファイル共有の論理的な削除を有効化
  share_properties {
    # 削除されたファイルを保持する日数
    retention_policy {
      days = 7
    }
  }
  # インフラストラクチャ暗号化の有効化
  infrastructure_encryption_enabled = false
  # タグ
  tags = {
    Name = var.project_name
  }
}

# ストレージコンテナの作成
resource "azurerm_storage_container" "blob" {
  # コンテナ名
  name = var.project_name
  # 所属させるストレージアカウント名
  storage_account_name = azurerm_storage_account.blob.name
  # 匿名アクセスレベル (private(Default)/blob/container)
  container_access_type = "blob"
  # メタデータ
  metadata = {}
  # 各種REST操作のタイムアウト
  timeouts {
    create = null # Default: 30min
    read   = null # Default: 30min
    update = null # Default: 5min
    delete = null # Default: 30min
  }
}

# ストレージコンテナへのファイルアップロード
locals {
  account   = azurerm_storage_container.blob.storage_account_name                 # ストレージアカウント名
  container = azurerm_storage_container.blob.name                                 # ストレージコンテナ名
  src_path  = "./webpage/*"                                                       # アップロード対象のファイル群
  dst_path  = "https://${local.account}.blob.core.windows.net/${local.container}" # アップロード先のURL
}
resource "null_resource" "fileupload" {
  # ストレージコンテナ作成完了後に実行
  triggers = {
    trigger = azurerm_storage_container.blob.id
  }
  # ローカルディレクトリにあるWebページをS3バケットにアップロード
  provisioner "local-exec" {
    command = "az storage copy -s ${local.src_path} -d ${local.dst_path} --account-key ${azurerm_storage_account.blob.primary_access_key} -r"
  }
}

# Blob Storage URLの表示
output "blob_storage_url" {
  description = "Blob Storage URL"
  value       = local.dst_path
}

# WebページURLの表示
output "webpage_url" {
  description = "Web Page URL"
  value       = "${local.dst_path}/index.html"
}
