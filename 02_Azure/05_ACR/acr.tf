#============================================================
# ACR
#============================================================

# ランダムな小文字16進数値の生成
resource "random_id" "acr" {
  byte_length = 2 # 値の範囲
}
locals {
  acr_lower_random_hex = random_id.acr.dec
}

# ACRの作成
resource "azurerm_container_registry" "acr" {
  # 所属させるリソースグループ
  resource_group_name = azurerm_resource_group.rg.name
  # レジストリ名
  name = "${var.project_name}${local.acr_lower_random_hex}"
  # 作成先のリージョン
  location = azurerm_resource_group.rg.location
  # 価格プラン (Basic/Standard/Premium)
  sku = var.acr_sku
  # 管理者ユーザーからのアクセス可否
  admin_enabled = true
  # パブリックアクセスの可否
  public_network_access_enabled = true
  # 匿名（未認証）ユーザーによるプルアクセスの可否
  anonymous_pull_enabled = false # Dafault: false (trueにしないこと)
  # タグ
  tags = {
    Name = var.project_name
  }
}

# コンテナイメージのビルドとACRリポジトリへのプッシュ
resource "null_resource" "main" {
  # ACRリポジトリ作成後に実行
  triggers = {
    trigger = azurerm_container_registry.acr.id
  }
  # ACRログイン
  provisioner "local-exec" {
    command = "az acr login --name ${azurerm_container_registry.acr.name}"
  }
  # コンテナのビルド
  provisioner "local-exec" {
    command = "docker build -t ${var.acr_image_name}:latest ${var.acr_dockerfile_dir}"
  }
  # コンテナ名の変更
  provisioner "local-exec" {
    command = "docker tag ${var.acr_image_name}:latest ${azurerm_container_registry.acr.name}.azurecr.io/${var.acr_image_name}:latest"
  }
  # ACRリポジトリへのコンテナのプッシュ
  provisioner "local-exec" {
    command = "docker push ${azurerm_container_registry.acr.name}.azurecr.io/${var.acr_image_name}:latest"
  }
}
