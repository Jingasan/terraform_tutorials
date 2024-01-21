#============================================================
# 環境変数の定義（terraform.tfvarsの変数値を受け取る）
#============================================================
# プロジェクトID
variable "project_id" {}
# リージョン
variable "region" {}
#============================================================
# Cloud Storage
#============================================================
# ストレージクラス
variable "gcs_storage_class" {}
#============================================================
# Certificate Manager
#============================================================
# ドメイン(事前にCloudDomainsで取得しておく)
variable "certificate_manager_domain" {}
