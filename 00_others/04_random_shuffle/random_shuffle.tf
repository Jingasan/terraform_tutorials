# 配列から指定された数の要素を取得
resource "random_shuffle" "sample" {
  input        = ["a", "b", "c", "d", "e"]
  result_count = 2
}
# 生成したUUIDの表示
output "ramdom_shuffle" {
  value = random_shuffle.sample.result
}
