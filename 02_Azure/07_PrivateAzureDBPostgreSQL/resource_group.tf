#============================================================
# Resource Group
#============================================================

# ランダムな小文字16進数値の生成
resource "random_id" "default" {
  byte_length = 2 # 値の範囲
}
locals {
  lower_random_hex = random_id.default.dec
}

# リソースグループの作成
resource "azurerm_resource_group" "rg" {
  # リソースグループ名
  name = "${var.project_name}${local.lower_random_hex}-rg"
  # リージョン
  location = var.location
  # タグ
  tags = {
    Name = var.project_name
  }
}
