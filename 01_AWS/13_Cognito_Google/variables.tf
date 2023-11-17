#============================================================
# 環境変数の定義
#============================================================
# プロジェクト名
variable "project_name" {}
#============================================================
# AWS Account
#============================================================
# AWSのリージョン
variable "region" {}
# AWSアクセスキーのプロファイル
variable "profile" {}
#============================================================
# Cognito
#============================================================
# OAuth2.0 APIによるGoogle認証のクライアントID 
variable "cognito_google_client_id" {}
# OAuth2.0 APIによるGoogle認証のクライアントシークレット
variable "cognito_google_client_secret" {}