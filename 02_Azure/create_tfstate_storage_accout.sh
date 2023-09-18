#!/bin/bash

RESOURCE_GROUP_NAME=terraform-tfstate-rg
STORAGE_ACCOUNT_NAME=tfstate$RANDOM
CONTAINER_NAME=tfstate

# リソースグループを作成
az group create \
  --name $RESOURCE_GROUP_NAME \
  --location japaneast

## ストレージアカウントを作成
az storage account create \
  --resource-group $RESOURCE_GROUP_NAME \
  --name $STORAGE_ACCOUNT_NAME \
  --sku Standard_LRS \
  --encryption-services blob

## コンテナーを作成
az storage container create \
  --name $CONTAINER_NAME \
  --account-name $STORAGE_ACCOUNT_NAME