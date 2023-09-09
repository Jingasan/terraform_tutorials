#============================================================
# VPC
#============================================================

# VPCの作成
resource "aws_vpc" "default" {
  # VPCのIPv4アドレスの指定
  cidr_block = var.vpc_cidr
  # AWSのDNSサーバーによる名前解決有効化
  enable_dns_support = true
  # VPC内のリソースにパブリックDNSホスト名を自動的に割り当て
  enable_dns_hostnames = true
  # AWSのハードウェアを占有使用したいかどうか（default：他ユーザーと共有するハードウェア上で起動）
  instance_tenancy = "default"
  # タグ
  tags = {
    Name = "${var.project_name}-vpc"
  }
}



#============================================================
# パブリックサブネット
#============================================================

# パブリックサブネットの作成
resource "aws_subnet" "public" {
  # 各パブリックサブネットを作成
  for_each = var.public_subnet_cidrs
  # サブネットを作成する対象のVPCのIDの指定
  vpc_id = aws_vpc.default.id
  # IPv4アドレスの範囲指定
  cidr_block = each.value
  # サブネットを作成するアベイラビリティゾーンの指定
  # アベイラビリティゾーンをまたがったサブネットは作成できない
  availability_zone = "${var.region}${each.key}"
  # そのサブネットで起動したインスタンスにパブリックIPを自動で割り当てる
  map_public_ip_on_launch = true
  # タグ
  tags = {
    Name = "${var.project_name}-public-${each.key}"
  }
}

# Internet Gatewayの作成
resource "aws_internet_gateway" "igw" {
  # Internet Gatewayを作成する対象のVPCのIDの指定
  vpc_id = aws_vpc.default.id
  # タグ
  tags = {
    Name = "${var.project_name}-igw"
  }
}

# VPCにデータを流すためのルーティング情報を管理するルートテーブルの作成
resource "aws_route_table" "public" {
  # ルートテーブルを作成する対象のVPCのIDの指定
  vpc_id = aws_vpc.default.id
  # タグ
  tags = {
    Name = "${var.project_name}-public-rtb"
  }
}

# Internet Gateway経由でVPC内からインターネットにデータを流すルートの作成
# ルートはルートテーブルの1レコードに該当する
resource "aws_route" "public" {
  # 関連付けるルートテーブルを指定
  route_table_id = aws_route_table.public.id
  # 関連付けるInternet Gatewayを指定
  gateway_id = aws_internet_gateway.igw.id
  # Internet Gateway経由でVPC内からインターネットにデータを流す設定
  destination_cidr_block = "0.0.0.0/0"
}

# パブリックサブネットへのルートテーブルの関連付け
# 関連付けを忘れると、デフォルトルートテーブルが自動的に使用されるが、
# デフォルトルートテーブルの利用はアンチパターンであるため、注意。
resource "aws_route_table_association" "public" {
  # 各パブリックサブネットに対してルートテーブルを関連付け
  for_each = aws_subnet.public
  # サブネット単位でどのルートテーブルを使ってルーティングするかを設定する
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}



#============================================================
# プライベートサブネット
#============================================================

# プライベートサブネットの作成
resource "aws_subnet" "private" {
  # 各パブリックサブネットを作成
  for_each = var.private_subnet_cidrs
  # サブネットを作成する対象のVPCのIDの指定
  vpc_id = aws_vpc.default.id
  # VPCのIPv4アドレスの指定(パブリックサブネットとは異なるCIDRブロックを指定)
  cidr_block = each.value
  # サブネットを作成するアベイラビリティゾーンの指定
  # アベイラビリティゾーンをまたがったサブネットは作成できない
  availability_zone = "${var.region}${each.key}"
  # そのサブネットで起動したインスタンスにパブリックIPを割り当てるかどうか
  map_public_ip_on_launch = true
  # タグ
  tags = {
    Name = "${var.project_name}-private-${each.key}"
  }
}

# EIP(Elastic IP Address)の設定
# NAT Gatewayに静的なパブリックIPアドレスを割り当てる
resource "aws_eip" "nat" {
  domain = "vpc"
  # EIPはInternet Gatewayに依存するため、Internet Gateway作成後に作成
  depends_on = [aws_internet_gateway.igw]
  # タグ
  tags = {
    Name = "${var.project_name}-eip"
  }
}

# NAT Gatewayの作成
# パブリックサブネットに配置したNAT Gateway経由で
# プライベートネットワークからインターネットへのアクセスできるようにする
resource "aws_nat_gateway" "default" {
  # NAT Gatewayを配置するサブネットIDの指定
  subnet_id = aws_subnet.public["a"].id
  # NAT Gatewayに静的なパブリックIPアドレスを割り当てる
  allocation_id = aws_eip.nat.id
  # NAT GatewayはInternet Gatewayに依存しているため、Internet Gateway作成後に作成
  depends_on = [aws_internet_gateway.igw]
  # タグ
  tags = {
    Name = "${var.project_name}-nat-gateway"
  }
}

# VPCにデータを流すためのルーティング情報を管理するルートテーブルの作成
resource "aws_route_table" "private" {
  # ルートテーブルを作成する対象のVPCのIDの指定
  vpc_id = aws_vpc.default.id
  # ルートの指定
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.default.id
  }
  # タグ
  tags = {
    Name = "${var.project_name}-private-rtb"
  }
}

# プライベートサブネットへのルートテーブルの関連付け
# 関連付けを忘れると、デフォルトルートテーブルが自動的に使用されるが、
# デフォルトルートテーブルの利用はアンチパターンであるため、注意。
resource "aws_route_table_association" "private" {
  # 各パブリックサブネットに対してルートテーブルを関連付け
  for_each = aws_subnet.private
  # サブネット単位でどのルートテーブルを使ってルーティングするかを設定する
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private.id
}



#============================================================
# VPC エンドポイント
#============================================================

# VPCエンドポイントの設定
# VPC（VPC内にあるEC2やLambda）からインターネットを経由（NAT Gateway → Internet Gateway経由）せずに
# S3に直接アクセスさせることで、NATゲートウェイ料金の削減・セキュリティ向上が見込める
resource "aws_vpc_endpoint" "s3_endpoint" {
  # VPCエンドポイントを作成する対象のVPCの指定
  vpc_id = aws_vpc.default.id
  # S3のサービス名
  service_name = "com.amazonaws.${var.region}.s3"
  # VPCからのS3接続時に許可するアクセスポリシーの指定
  policy = <<POLICY
    {
        "Statement": [
            {
                "Action": "*",
                "Effect": "Allow",
                "Resource": "*",
                "Principal": "*"
            }
        ]
    }
    POLICY
  # タグ
  tags = {
    Name = "${var.project_name}-vpce-s3"
  }
}

# VPCエンドポイントのルートテーブルへの関連付け
resource "aws_vpc_endpoint_route_table_association" "private_s3" {
  # 関連付けるVPCエンドポイントを指定
  vpc_endpoint_id = aws_vpc_endpoint.s3_endpoint.id
  # 関連付け先のルートテーブルを指定
  route_table_id = aws_route_table.private.id
}
