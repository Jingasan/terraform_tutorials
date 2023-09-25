#============================================================
# Terraform 基本設定
#============================================================
terraform {
  # Terraformのバージョン指定
  required_version = ">= 1.5.7"

  # Azureのバージョン指定
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~>3.0"
    }
  }

  # .tfstateをBlob Storageで管理する設定
  # terraform initをする前に以下の保管用バケットをBlob Storageに作成しておく必要がある
  # backend "azurerm" {
  #   resource_group_name  = "terraform-tfstate-rg"     # .tfstateを保管するストレージアカウントを所属させるリソースグループ名
  #   storage_account_name = "terraformtutorialtfstate" # .tfstateを保管するストレージアカウント名
  #   container_name       = "terraformtutorialtfstate" # .tfstateを保管するストレージコンテナ名
  #   key                  = "terraform.tfstate"        # 保管される.tfstateのファイル名
  # }
}



#============================================================
# クラウドプロバイダの設定
#============================================================
provider "azurerm" {
  features {
    resource_group {
      # リソースが残っているリソースグループを削除しないか
      prevent_deletion_if_contains_resources = false
    }
  }
}
