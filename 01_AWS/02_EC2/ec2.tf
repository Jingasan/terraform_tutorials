# EC2 Key pair
variable "key_name" {
  default = "terraform-handson-keypair"
}

# 秘密鍵のアルゴリズム設定
resource "tls_private_key" "handson_private_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

# クライアントPCにKey pair（秘密鍵と公開鍵）を作成
# - Windowsの場合はフォルダを"\\"で区切る（エスケープする必要がある）
# - [terraform apply] 実行後はクライアントPCの公開鍵は自動削除される
locals {
  public_key_file  = "./${var.key_name}.id_rsa.pub"
  private_key_file = "./${var.key_name}.id_rsa"
  #public_key_file  = ".\\${var.key_name}.id_rsa.pub"
  #private_key_file = ".\\${var.key_name}.id_rsa"
}
resource "local_file" "handson_private_key_pem" {
  filename = local.private_key_file
  content  = tls_private_key.handson_private_key.private_key_pem
}

# 上記で作成した公開鍵をAWSのKey pairにインポート
resource "aws_key_pair" "handson_keypair" {
  key_name   = var.key_name
  public_key = tls_private_key.handson_private_key.public_key_openssh
}

# EC2の作成
data "aws_ssm_parameter" "amzn2_latest_ami" {
  # Amazon Linux 2 の最新版AMIを取得
  name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}
resource "aws_instance" "handson_ec2" {
  ami                         = data.aws_ssm_parameter.amzn2_latest_ami.value
  instance_type               = "t2.micro"
  availability_zone           = "ap-northeast-1a"
  vpc_security_group_ids      = [aws_security_group.handson_ec2_sg.id]
  subnet_id                   = aws_subnet.handson_public_1a_sn.id
  associate_public_ip_address = "true"
  key_name                    = var.key_name

  # タグ
  tags = {
    Name = "Terraform検証用"
  }
}

# 作成したEC2のパブリックIPアドレスを出力
output "ec2_global_ips" {
  value = aws_instance.handson_ec2.*.public_ip
}
