#============================================================
# Resource Group
#============================================================

# リソースグループの作成
resource "azurerm_resource_group" "rg" {
  # リソースグループ名
  name = "${var.project_name}-rg"
  # リージョン
  location = "japaneast"
  # タグ
  tags = {
    Name = var.project_name
  }
}
