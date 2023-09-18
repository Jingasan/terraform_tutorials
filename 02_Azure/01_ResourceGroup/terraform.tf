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
  }

  # .tfstateをBlob Storageで管理する設定
  # terraform initをする前に以下の保管用バケットをBlob Storageに作成しておく必要がある
  # backend "azurerm" {
  #   resource_group_name  = "terraform-tfstate-rg"
  #   storage_account_name = "terraformtutorialtfstate"
  #   container_name       = "terraformtutorialtfstate"
  #   key                  = "terraform.tfstate"
  # }
}



#============================================================
# クラウドプロバイダの設定
#============================================================
provider "azurerm" {
  # Resource Providerを登録していない場合に発生するエラーの回避設定
  #skip_provider_registration = true
  features {}
}
