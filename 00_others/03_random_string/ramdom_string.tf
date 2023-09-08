# ランダムな文字列の生成
resource "random_string" "sample" {
  length  = 16
  special = true
}
# 生成したUUIDの表示
output "ramdom_string" {
  value = random_string.sample.result
}
