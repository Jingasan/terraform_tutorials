#============================================================
# Azure Functions
#============================================================

# ランダムな小文字16進数値の生成
resource "random_id" "blob" {
  byte_length = 2 # 値の範囲
}
locals {
  lower_random_hex = random_id.blob.dec
}

# App Serviceの作成
resource "azurerm_service_plan" "functions" {
  # 所属させるリソースグループ
  resource_group_name = azurerm_resource_group.rg.name
  # App Service名
  name = "${var.project_name}${local.lower_random_hex}"
  # 作成先のリージョン
  location = azurerm_resource_group.rg.location
  # OSの種類
  os_type = "Linux"
  # App Serviceの価格プラン (Y1/EP1/EP2/EP3/B1/B2/B3/S1/S2/S3/P1v2/P2v2/P3v2)
  # https://azure.microsoft.com/ja-jp/pricing/details/app-service/linux/
  sku_name = var.functions_sku_name
  # タグ
  tags = {
    Name = var.project_name
  }
}

# Azure Functionsの作成
resource "azurerm_linux_function_app" "functions" {
  # 所属させるリソースグループ
  resource_group_name = azurerm_resource_group.rg.name
  # ストレージアカウント名
  name = "${var.project_name}${local.lower_random_hex}"
  # 作成先のリージョン
  location = azurerm_resource_group.rg.location
  # ストレージアカウント名
  storage_account_name = azurerm_storage_account.functions.name
  # ストレージアカウントのアクセスキー
  storage_account_access_key = azurerm_storage_account.functions.primary_access_key
  # サービスプランのID
  service_plan_id = azurerm_service_plan.functions.id
  # 関数を有効化
  enabled = true
  # HTTPSに限定するか（HTTPを許容するか）
  https_only = true
  # 環境変数の設定
  app_settings = {
    "ENV_NAME" = "ENV_VALUE"
  }
  site_config {
    # Azure Functionsのランタイムとバージョンの設定
    application_stack {
      node_version = var.functions_node_version
    }
    # Azure FunctionsのログをApplication Insightsに書き出すための接続文字列の指定
    application_insights_connection_string = azurerm_application_insights.function.connection_string
  }
  # タグ
  tags = {
    Name = var.project_name
  }
}

# Azure Functionsの関数のビルドとアップロード
locals {
  func_dir = "./api"
}
resource "null_resource" "functions_build_upload" {
  triggers = {
    # Azure FunctionsとBlob Storageが生成されたら実行
    azure_functions_id       = azurerm_linux_function_app.functions.id
    azure_storage_account_id = azurerm_storage_account.functions.id
    # ソースコードに差分があった場合に実行
    code_diff = join("", [
      for file in fileset("${local.func_dir}/src", "{*.ts, function.json}")
      : filebase64("${local.func_dir}/src/${file}")
    ])
    package_diff = join("", [
      for file in fileset("${local.func_dir}", "{package*.json, host.json}")
      : filebase64("${local.func_dir}/${file}")
    ])
  }
  # 関数の依存パッケージのインストール
  provisioner "local-exec" {
    # 実行するコマンド
    command = "npm install"
    # コマンドを実行するディレクトリ
    working_dir = local.func_dir
  }
  # 関数のビルド
  provisioner "local-exec" {
    command     = "npm run build"
    working_dir = local.func_dir
  }
  # 関数アプリにアップロードできるようになるまで暫く待機
  provisioner "local-exec" {
    command = "sleep 30"
  }
  # 関数のアップロード
  provisioner "local-exec" {
    command     = "npx func azure functionapp publish ${azurerm_linux_function_app.functions.name}"
    working_dir = local.func_dir
  }
}

# Azure Functions API Hostname
output "azure_functions_hostname" {
  description = "Azure Functions Hostname"
  value       = azurerm_linux_function_app.functions.default_hostname
}

# Azure Functions API URL
output "azure_functions_api_url" {
  description = "Azure Functions API URL"
  value       = "${azurerm_linux_function_app.functions.default_hostname}/api/~"
}



#============================================================
# Application Insights (Azure Functionsのログモニタリング用)
#============================================================

#　Application Insightsの作成
resource "azurerm_application_insights" "function" {
  # 所属させるリソースグループ
  resource_group_name = azurerm_resource_group.rg.name
  # Application Insights名
  name = "${var.project_name}${local.lower_random_hex}"
  # 作成先のリージョン
  location = azurerm_resource_group.rg.location
  # アプリケーションのタイプ
  application_type = "web"
  # タグ
  tags = {
    Name = var.project_name
  }
}



#============================================================
# Blob Storage (Azure Functionsの関数保管用)
#============================================================

# ストレージアカウントの作成
resource "azurerm_storage_account" "functions" {
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
  account_tier = var.account_storage_account_tier
  # 冗長性 (LRS/GRS/RAGRS/ZRS/GZRS/RAGZRS)
  account_replication_type = var.account_storage_account_replication_type
  # タグ
  tags = {
    Name = var.project_name
  }
}
