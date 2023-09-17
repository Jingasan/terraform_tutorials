
# リソースグループを作成
az group create \
  --name terraform-tfstate-rg \
  --location japaneast

## ストレージアカウントを作成
az storage account create \
  --resource-group terraform-tfstate-rg \
  --name terraformtutorialtfstate \
  --sku Standard_LRS \
  --encryption-services blob

## コンテナーを作成
az storage container create \
  --name terraformtutorialtfstate \
  --account-name terraformtutorialtfstate