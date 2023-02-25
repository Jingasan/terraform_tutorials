# ローカル変数の定義
locals {
  content  = "use local values."
  filename = "hello_local.txt"
}

# ローカル変数値の利用
resource "local_file" "local_sample" {
  content         = local.content
  filename        = local.filename
  file_permission = 644
}
