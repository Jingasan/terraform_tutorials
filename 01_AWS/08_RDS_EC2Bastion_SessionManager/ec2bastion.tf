#============================================================
# RDS接続用のEC2踏み台サーバー
#============================================================

# EC2インスタンスのイメージ
data "aws_ami" "amazon_linux" {
  # 利用するAmazonマシンイメージ
  filter {
    name   = "name"
    values = ["al2023-ami-2023.1.*-kernel-6.*-x86_64"]
  }
  # Amazon公式のamiを取得
  owners = ["amazon"]
  # 最新のamiを取得
  most_recent = true
}

# EC2インスタンスの作成
resource "aws_instance" "bastion" {
  # Amazonマシンイメージ
  ami = data.aws_ami.amazon_linux.id
  # インスタンスタイプ
  instance_type = "t2.micro"
  # EC2インスタンスへのIAMロール割り当て（SessionManager経由でアクセスする権限）
  iam_instance_profile = aws_iam_instance_profile.systems-manager.name
  # パブリックIPアドレスを割り当てない
  associate_public_ip_address = "false"
  # EC2インスタンスを所属させるサブネット
  subnet_id = aws_subnet.private["a"].id
  # EC2インスタンスに割り当てるセキュリティグループ
  vpc_security_group_ids = [
    aws_security_group.bastion.id
  ]
  # EC2インスタンス内で初期実行するスクリプト
  user_data = file("./bastion/user-data.sh")
  # タグ
  tags = {
    Name = var.project_name
  }
}

# 踏み台EC2サーバーのセキュリティグループ
resource "aws_security_group" "bastion" {
  # セキュリティグループ名
  name = "${var.project_name}-bastion-sg"
  # セキュリティグループを作成する対象のVPCの指定
  vpc_id = aws_vpc.default.id
  # 説明
  description = "${var.project_name} ec2 bastion security group"
  # タグ
  tags = {
    Name = var.project_name
  }
}

# 踏み台EC2サーバーのセキュリティグループに割り当てるアウトバウンドルール
resource "aws_security_group_rule" "ec2_egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.bastion.id
}

# インスタンスプロファイル（EC2インスタンスへのIAMロール割り当て）
resource "aws_iam_instance_profile" "systems-manager" {
  name = "${var.project_name}-ec2-instance-profile"
  role = aws_iam_role.ec2.name
}

# IAMロール
resource "aws_iam_role" "ec2" {
  # IAMロール名
  name = "${var.project_name}-iam-role"
  # IAMロールの割り当て先（EC2）
  assume_role_policy = data.aws_iam_policy_document.ec2.json
}

# IAMロールの割り当て先（EC2）
data "aws_iam_policy_document" "ec2" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# IAMロールへのポリシーの割り当て
resource "aws_iam_role_policy_attachment" "ec2" {
  # 割り当て先のIAMロール
  role = aws_iam_role.ec2.name
  # 割り当てるポリシーのARN（SystemManager）
  policy_arn = data.aws_iam_policy.systems-manager.arn
}

data "aws_iam_policy" "systems-manager" {
  arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
