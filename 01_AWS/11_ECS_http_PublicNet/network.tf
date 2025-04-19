#==============================
# VPC
#==============================

# VPCの作成
resource "aws_vpc" "example" {
  # VPCのIPv4アドレスの指定
  cidr_block = "10.0.0.0/16"
  # AWSのDNSサーバーによる名前解決有効化
  enable_dns_support = true
  # VPC内のリソースにパブリックDNSホスト名を自動的に割り当て
  enable_dns_hostnames = true
  # タグ
  tags = {
    Name = "Terraform検証用"
  }
}


#==============================
# パブリックサブネット
#==============================

# パブリックサブネットの作成
resource "aws_subnet" "public_a" {
  # サブネットを作成する対象のVPCのIDの指定
  vpc_id = aws_vpc.example.id
  # IPv4アドレスの範囲指定
  cidr_block = "10.0.0.0/24"
  # サブネットを作成するアベイラビリティゾーンの指定
  # アベイラビリティゾーンをまたがったサブネットは作成できない
  availability_zone = "ap-northeast-1a"
  # タグ
  tags = {
    Name = "Terraform検証用 PublicSubnet-A"
  }
}
resource "aws_subnet" "public_c" {
  # サブネットを作成する対象のVPCのIDの指定
  vpc_id = aws_vpc.example.id
  # IPv4アドレスの範囲指定
  cidr_block = "10.0.1.0/24"
  # サブネットを作成するアベイラビリティゾーンの指定
  availability_zone = "ap-northeast-1c"
  # タグ
  tags = {
    Name = "Terraform検証用 PublicSubnet-C"
  }
}

# Internet Gatewayの作成
resource "aws_internet_gateway" "igw" {
  # Internet Gatewayを作成する対象のVPCのIDの指定
  vpc_id = aws_vpc.example.id
  # タグ
  tags = {
    Name = "Terraform検証用"
  }
}

# VPCにデータを流すためのルーティング情報を管理するルートテーブルの作成
resource "aws_route_table" "public" {
  # ルートテーブルを作成する対象のVPCのIDの指定
  vpc_id = aws_vpc.example.id
  # タグ
  tags = {
    Name = "Terraform検証用 RouteTable-public"
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
resource "aws_route_table_association" "public_a" {
  # サブネット単位でどのルートテーブルを使ってルーティングするかを設定する
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}
resource "aws_route_table_association" "public_c" {
  # サブネット単位でどのルートテーブルを使ってルーティングするかを設定する
  subnet_id      = aws_subnet.public_c.id
  route_table_id = aws_route_table.public.id
}
