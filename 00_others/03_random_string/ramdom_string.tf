# ランダムな文字列の生成
resource "random_string" "sample" {
  length  = 16
  special = true
}
# 生成した文字列の表示
output "ramdom_string" {
  value = random_string.sample.result
}
