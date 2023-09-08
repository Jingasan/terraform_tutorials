# AWSアカウントIDの取得
data "aws_caller_identity" "current" {}
# AWSアカウントIDの表示
output "account_id" {
  value = data.aws_caller_identity.current.account_id
}
