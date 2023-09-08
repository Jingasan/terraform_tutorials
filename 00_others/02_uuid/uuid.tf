resource "random_uuid" "sample" {}
output "ramdom_uuid" {
  value = random_uuid.sample.result
}
