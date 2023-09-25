#============================================================
# Azure Batch
#============================================================

# ランダムな小文字16進数値の生成
resource "random_id" "batch" {
  byte_length = 2 # 値の範囲
}
locals {
  batch_lower_random_hex = random_id.batch.dec
}

# Batchアカウントの作成
resource "azurerm_batch_account" "batch" {
  # 所属させるリソースグループ
  resource_group_name = azurerm_resource_group.rg.name
  # アカウント名
  name = "${var.project_name}${local.batch_lower_random_hex}"
  # 作成先のリージョン
  location = azurerm_resource_group.rg.location
  # Batchアカウントに紐付けるストレージアカウントのID
  storage_account_id = azurerm_storage_account.batch.id
  # ストレージアカウントの認証モード (StorageKeys/BatchAccountManagedIdentity)
  storage_account_authentication_mode = "StorageKeys"
  # システム割り当てマネージドID：ON
  identity {
    type = "SystemAssigned"
  }
  # プール割り当てモード
  pool_allocation_mode = "BatchService"
  # 認証モード (AAD: Microsoft Entra ID／SharedKey: 共有キー／TaskAuthenticationToken: タスク認証トークン)
  allowed_authentication_modes = ["AAD", "SharedKey", "TaskAuthenticationToken"]
  # パブリックネットワークアクセスの有効化
  public_network_access_enabled = true
  # タグ
  tags = {
    Name = var.project_name
  }
}



#============================================================
# Blob Storage (Azure Batch用)
#============================================================

# ストレージアカウントの作成
resource "azurerm_storage_account" "batch" {
  # 所属させるリソースグループ
  resource_group_name = azurerm_resource_group.rg.name
  # ストレージアカウント名
  name = "${var.project_name}${local.batch_lower_random_hex}"
  # 作成先のリージョン
  location = azurerm_resource_group.rg.location
  # アカウントの種類
  account_kind = "StorageV2"
  # 価格プラン (Standard/Premium)
  account_tier = var.storage_account_tier
  # 冗長性 (LRS/GRS/RAGRS/ZRS/GZRS/RAGZRS)
  account_replication_type = var.storage_account_replication_type
  # タグ
  tags = {
    Name = var.project_name
  }
}
