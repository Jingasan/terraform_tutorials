# ランダムIDの生成（b64_url, b64_std, hex, dec の４種類の乱数を生成）
resource "random_id" "sample" {
  byte_length = 8
}
# base64 urlの表示
output "ramdom_id-b64_url" {
  value = random_id.sample.b64_url
}
# base64 stdの表示
output "ramdom_id-b64_std" {
  value = random_id.sample.b64_std
}
# 生成した16進数値の表示
output "ramdom_id-hex" {
  value = random_id.sample.hex
}
# 生成した10進数値の表示
output "ramdom_id-dec" {
  value = random_id.sample.dec
}
