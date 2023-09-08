# UUIDの生成
resource "random_uuid" "sample" {}
# 生成したUUIDの表示
output "ramdom_uuid" {
  value = random_uuid.sample.result
}
