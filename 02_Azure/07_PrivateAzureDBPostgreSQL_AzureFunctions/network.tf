#============================================================
# Virtual Network
#============================================================

# 仮想ネットワークの作成
resource "azurerm_virtual_network" "default" {
  # 所属させるリソースグループ
  resource_group_name = azurerm_resource_group.rg.name
  # 仮想ネットワーク名
  name = "${var.project_name}${local.lower_random_hex}"
  # 作成先のリージョン
  location = azurerm_resource_group.rg.location
  # 仮想ネットワークのIPアドレス空間
  address_space = ["10.10.0.0/16"]
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
    name = "${var.project_name}${local.lower_random_hex}-security-rule"
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

# DBサーバー用のサブネット名
resource "azurerm_subnet" "db" {
  # 所属させるリソースグループ
  resource_group_name = azurerm_resource_group.rg.name
  # サブネット名
  name = "subnet-db"
  # 作成先のリージョン
  virtual_network_name = azurerm_virtual_network.default.name
  # サブネットアドレス範囲
  address_prefixes = ["10.10.10.0/24"]
  # サブネットに割り当てたプライベートリンクサービスのネットワークポリシーの有効化
  private_link_service_network_policies_enabled = true
  # サブネットに割り当てるサービスエンドポイントのリスト
  # 仮想ネットワークからこのサービスエンドポイントを介してDBサーバーへのトラフィックを許可する
  service_endpoints = ["Microsoft.Storage"]
  # 委任設定
  delegation {
    # 委任設定の名称
    name = "Microsoft.DBforPostgreSQL.flexibleServers"
    # 委任先のAzureサービス
    service_delegation {
      # 委任先のサービス名
      name = "Microsoft.DBforPostgreSQL/flexibleServers"
      # 委任するアクション：PostgreSQLフレキシブルサーバーをこのサブネットに含める
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }
  # サブネットに割り当てたプライベートエンドポイントのネットワークポリシーの有効化
  private_endpoint_network_policies_enabled = true
}

# DBサーバー用のサブネットにセキュリティグループを設定
resource "azurerm_subnet_network_security_group_association" "db" {
  # サブネットID
  subnet_id = azurerm_subnet.db.id
  # セキュリティグループ
  network_security_group_id = azurerm_network_security_group.default.id
}

# DBサーバー用のサブネット名
resource "azurerm_subnet" "functions" {
  # 所属させるリソースグループ
  resource_group_name = azurerm_resource_group.rg.name
  # サブネット名
  name = "subnet-functions"
  # 作成先のリージョン
  virtual_network_name = azurerm_virtual_network.default.name
  # サブネットアドレス範囲
  address_prefixes = ["10.10.20.0/24"]
  # サブネットに割り当てたプライベートリンクサービスのネットワークポリシーの有効化
  private_link_service_network_policies_enabled = true
  # サブネットに割り当てるサービスエンドポイントのリスト
  # 仮想ネットワークからこのサービスエンドポイントを介してAzureFunctionsへのトラフィックを許可する
  service_endpoints = ["Microsoft.Web"]
  # 委任設定
  delegation {
    # 委任設定の名称
    name = "Microsoft.Web.serverFarms"
    # 委任先のAzureサービス
    service_delegation {
      # 委任先のサービス名
      name = "Microsoft.Web/serverFarms"
      # 委任するアクション：Azure Functionsからこのサブネット内のリソースに対する操作を許可する
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/action",
      ]
    }
  }
  # サブネットに割り当てたプライベートエンドポイントのネットワークポリシーの有効化
  private_endpoint_network_policies_enabled = true
}

# DBサーバー用のサブネットにセキュリティグループを設定
resource "azurerm_subnet_network_security_group_association" "functions" {
  # サブネットID
  subnet_id = azurerm_subnet.functions.id
  # セキュリティグループ
  network_security_group_id = azurerm_network_security_group.default.id
}

# プライベートDNSゾーンの作成
resource "azurerm_private_dns_zone" "postgres" {
  # サブネットとセキュリティグループの関連付け後にプライベートDNSゾーンを作成
  depends_on = [
    azurerm_subnet_network_security_group_association.db,
    azurerm_subnet_network_security_group_association.functions
  ]
  # 所属させるリソースグループ
  resource_group_name = azurerm_resource_group.rg.name
  # プライベートDNSゾーン名
  name = "${var.project_name}${local.lower_random_hex}-pdz.postgres.database.azure.com"
  # タグ
  tags = {
    Name = var.project_name
  }
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
  # タグ
  tags = {
    Name = var.project_name
  }
}
