#==============================
# セキュリティグループ
#==============================

# 引数の定義
variable "name" {
  type = string
}
variable "vpc_id" {
  type = string
}
variable "port" {
  type = string
}
variable "cidr_blocks" {
  type = list(string)
}

# セキュリティグループの作成
resource "aws_security_group" "default" {
  # セキュリティグループ名
  name = var.name
  # セキュリティグループを割り当てるVPCのID
  vpc_id = var.vpc_id
  # 説明
  description = "Terraform Test"
  # タグ
  tags = {
    Name = "Terraform検証用"
  }
}

# インバウンドルール(VPC外からインスタンスへのアクセスルール)の追加
resource "aws_security_group_rule" "ingress" {
  # 関連付けるセキュリティグループID
  security_group_id = aws_security_group.default.id
  # typeをingressにすることでインバウンドルールになる
  type = "ingress"
  # 通信を許可するプロトコル/ポート番号/IP
  from_port   = var.port
  to_port     = var.port
  protocol    = "tcp"
  cidr_blocks = var.cidr_blocks
  # 説明
  description = "Terraform Test"
}

# アウトバウンドルール(インスタンスからVPC外へのアクセスルール)の追加
resource "aws_security_group_rule" "egress" {
  # 関連付けるセキュリティグループID
  security_group_id = aws_security_group.default.id
  # typeをegressにすることでアウトバウンドルールになる
  type = "egress"
  # 追加するルール：すべての通信を許可
  from_port   = 0
  to_port     = 0
  protocol    = "all"
  cidr_blocks = ["0.0.0.0/0"]
  # 説明
  description = "Terraform Test"
}

# 返り値の定義
output "security_group_id" {
  value = aws_security_group.default.id
}
