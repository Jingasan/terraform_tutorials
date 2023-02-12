### VPC

# VPCの設定
resource "aws_vpc" "handson_vpc"{
  cidr_block           = "10.0.0.0/16"

  # DNSホスト名の有効化
  enable_dns_hostnames = true

  # タグ
  tags = {
    Name = "Terraform検証用"
  }
}

# Subnetの設定
resource "aws_subnet" "handson_public_1a_sn" {
  # VPCの指定
  vpc_id            = aws_vpc.handson_vpc.id
  cidr_block        = "10.0.1.0/24"

  # アベイラビリティゾーン
  availability_zone = "ap-northeast-1a"

  # タグ
  tags = {
    Name = "Terraform検証用"
  }
}

# Internet Gatewayの設定
resource "aws_internet_gateway" "handson_igw" {
  # VPCの指定
  vpc_id = aws_vpc.handson_vpc.id

  # タグ
  tags = {
    Name = "Terraform検証用"
  }
}

# Route tableの作成
resource "aws_route_table" "handson_public_rt" {
  # VPCの指定
  vpc_id            = aws_vpc.handson_vpc.id
  route {
    cidr_block      = "0.0.0.0/0"
    gateway_id      = aws_internet_gateway.handson_igw.id
  }

  # タグ
  tags = {
    Name = "Terraform検証用"
  }
}

# SubnetとRoute tableの関連付け
resource "aws_route_table_association" "handson_public_rt_associate" {
  subnet_id      = aws_subnet.handson_public_1a_sn.id
  route_table_id = aws_route_table.handson_public_rt.id
}

# Security Groupの作成
data "http" "ifconfig" {
  # 自分のパブリックIP取得
  url = "http://ipv4.icanhazip.com/"
}
variable "allowed_cidr" {
  default = null
}
locals {
  myip          = chomp(data.http.ifconfig.body)
  allowed_cidr  = (var.allowed_cidr == null) ? "${local.myip}/32" : var.allowed_cidr
}
resource "aws_security_group" "handson_ec2_sg" {
  name              = "terraform-handson-ec2-sg"
  description       = "For EC2 Linux"
  vpc_id            = aws_vpc.handson_vpc.id

  # インバウンドルール
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [local.allowed_cidr]
  }

  # アウトバウンドルール
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # タグ
  tags = {
    Name = "Terraform検証用"
  }
}