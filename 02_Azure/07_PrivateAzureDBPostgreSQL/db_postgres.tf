#============================================================
# Azure Database for PostgreSQL
#============================================================

# ランダムな小文字16進数値の生成
resource "random_id" "postgres" {
  byte_length = 2 # 値の範囲
}
locals {
  lower_random_hex = random_id.postgres.dec
}

# 仮想ネットワークの作成
resource "azurerm_virtual_network" "default" {
  # 所属させるリソースグループ
  resource_group_name = azurerm_resource_group.rg.name
  # 仮想ネットワーク名
  name = "${var.project_name}${local.lower_random_hex}"
  # 作成先のリージョン
  location = azurerm_resource_group.rg.location
  # 仮想ネットワークのIPアドレス空間
  address_space = ["10.0.0.0/16"]
  # タグ
  tags = {
    Name = var.project_name
  }
}

# セキュリティグループの作成
resource "azurerm_network_security_group" "default" {
  # 所属させるリソースグループ
  resource_group_name = azurerm_resource_group.rg.name
  # 仮想ネットワーク名
  name = "${var.project_name}${local.lower_random_hex}-sg"
  # 作成先のリージョン
  location = azurerm_resource_group.rg.location
  # セキュリティルール
  security_rule {
    # セキュリティルール名称
    name = "${var.project_name}${local.lower_random_hex}-sg"
    # 優先度
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  # タグ
  tags = {
    Name = var.project_name
  }
}

# サブネット名
resource "azurerm_subnet" "default" {
  # 所属させるリソースグループ
  resource_group_name = azurerm_resource_group.rg.name
  # サブネット名
  name = "${var.project_name}${local.lower_random_hex}-subnet-db"
  # 作成先のリージョン
  virtual_network_name = azurerm_virtual_network.default.name
  # サブネットアドレス範囲
  address_prefixes = ["10.0.2.0/24"]
  #
  service_endpoints = ["Microsoft.Storage"]
  #
  delegation {
    name = "fs"
    service_delegation {
      name = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }
}

# サブネットとセキュリティグループの関連付け
resource "azurerm_subnet_network_security_group_association" "default" {
  # サブネットID
  subnet_id = azurerm_subnet.default.id
  # セキュリティグループ
  network_security_group_id = azurerm_network_security_group.default.id
}

# プライベートDNSゾーンの作成
resource "azurerm_private_dns_zone" "postgres" {
  # サブネットとセキュリティグループの関連付け後にプライベートDNSゾーンを作成
  depends_on = [azurerm_subnet_network_security_group_association.default]
  # 所属させるリソースグループ
  resource_group_name = azurerm_resource_group.rg.name
  # プライベートDNSゾーン名
  name = "${var.project_name}${local.lower_random_hex}-pdz.postgres.database.azure.com"
}

# プライベートDNSゾーンと仮想ネットワークのリンク
resource "azurerm_private_dns_zone_virtual_network_link" "postgres" {
  # 所属させるリソースグループ
  resource_group_name = azurerm_resource_group.rg.name
  # リンク名
  name = "${var.project_name}${local.lower_random_hex}-pdzvnetlink.com"
  # 割り当てるプライベートDNSゾーン名
  private_dns_zone_name = azurerm_private_dns_zone.postgres.name
  # 割り当て先の仮想ネットワークのID
  virtual_network_id = azurerm_virtual_network.default.id
}

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
  delegated_subnet_id = azurerm_subnet.default.id
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
