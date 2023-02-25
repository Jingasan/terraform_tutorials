# 入力変数の定義
variable "content" {
  default = "use input variables default value."
}
variable "filename" {
  default = "default_input.txt"
}

# 入力変数値の利用
resource "local_file" "input_sample" {
  content         = var.content
  filename        = var.filename
  file_permission = 644
}
