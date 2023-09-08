# 指定範囲からランダムな整数値の生成
resource "random_integer" "sample" {
  min = 1
  max = 99999
}
# 生成した整数値の表示
output "ramdom_integer" {
  value = random_integer.sample.result
}
