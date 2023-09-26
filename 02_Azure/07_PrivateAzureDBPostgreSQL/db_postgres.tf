#============================================================
# Azure Database for PostgreSQL
#============================================================

# Azure Database for PostgreSQL フレキシブルサーバーの作成
resource "azurerm_postgresql_flexible_server" "postgres" {
  # プライベートDNSゾーンと仮想ネットワークの関連付け後にPostgreSQLサーバーを作成
  depends_on = [azurerm_private_dns_zone_virtual_network_link.postgres]
  # 所属させるリソースグループ
  resource_group_name = azurerm_resource_group.rg.name
  # サーバー名
  name = "${var.project_name}${local.lower_random_hex}"
  # 作成先のリージョン
  location = azurerm_resource_group.rg.location
  # PostgreSQLのバージョン
  version = var.db_postgres_version
  # コンピューティングサイズ（価格プラン）
  sku_name = var.db_sku_name
  # ストレージサイズ (MB) (32GB - 32TB)
  storage_mb = var.db_storage_mb
  # ストレージの自動拡張
  auto_grow_enabled = true
  # バックアップ保存期間 (日) (7-35日)
  backup_retention_days = var.db_backup_retention_days
  # Geo冗長バックアップの有効化
  geo_redundant_backup_enabled = false
  # 可用性ゾーンの指定 (1/2/3)
  zone = "1"
  # 認証方法
  authentication {
    active_directory_auth_enabled = false
    password_auth_enabled         = true
  }
  # 管理者ユーザー名
  administrator_login = var.db_administrator_login
  # パスワード
  administrator_password = var.db_administrator_password
  # プライベートアクセスの設定：仮想ネットワーク統合
  delegated_subnet_id = azurerm_subnet.db.id
  # プライベートアクセスの設定：プライベートDNSゾーン統合
  private_dns_zone_id = azurerm_private_dns_zone.postgres.id
  # タグ
  tags = {
    Name = var.project_name
  }
}

# PostgreSQLフレキシブルサーバーのホスト名の出力
output "DatabaseHostname" {
  value = azurerm_postgresql_flexible_server.postgres.fqdn
}
