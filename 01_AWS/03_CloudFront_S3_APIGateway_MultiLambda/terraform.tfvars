#============================================================
# 環境変数値（variable.tfのデフォルト値を上書きする）
#============================================================
# AWSのリージョン
region = "ap-northeast-1"
# AWSアクセスキーのプロファイル
profile = "default"
#============================================================
# S3
#============================================================
# バケットの中にオブジェクトが入っていてもTerraformにバケットの削除を許可するかどうか(true:許可)
s3_bucket_force_destroy = true
