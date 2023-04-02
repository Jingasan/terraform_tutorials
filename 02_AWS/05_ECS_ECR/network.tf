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
  # そのサブネットで起動したインスタンスにパブリックIPを自動で割り当てる
  map_public_ip_on_launch = true
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
  # そのサブネットで起動したインスタンスにパブリックIPを自動で割り当てる
  map_public_ip_on_launch = true
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


#==============================
# プライベートサブネット
#==============================

# プライベートサブネットの作成
resource "aws_subnet" "private_a" {
  # サブネットを作成する対象のVPCのIDの指定
  vpc_id = aws_vpc.example.id
  # VPCのIPv4アドレスの指定(パブリックサブネットとは異なるCIDRブロックを指定)
  cidr_block = "10.0.128.0/24"
  # サブネットを作成するアベイラビリティゾーンの指定
  # アベイラビリティゾーンをまたがったサブネットは作成できない
  availability_zone = "ap-northeast-1a"
  # そのサブネットで起動したインスタンスにパブリックIPを割り当てない
  map_public_ip_on_launch = false
  # タグ
  tags = {
    Name = "Terraform検証用 PrivateSubnet-A"
  }
}
resource "aws_subnet" "private_c" {
  # サブネットを作成する対象のVPCのIDの指定
  vpc_id = aws_vpc.example.id
  # VPCのIPv4アドレスの指定(パブリックサブネットとは異なるCIDRブロックを指定)
  cidr_block = "10.0.129.0/24"
  # サブネットを作成するアベイラビリティゾーンの指定
  # アベイラビリティゾーンをまたがったサブネットは作成できない
  availability_zone = "ap-northeast-1c"
  # そのサブネットで起動したインスタンスにパブリックIPを割り当てない
  map_public_ip_on_launch = false
  # タグ
  tags = {
    Name = "Terraform検証用 PrivateSubnet-C"
  }
}

# VPCにデータを流すためのルーティング情報を管理するルートテーブルの作成
resource "aws_route_table" "private_a" {
  # ルートテーブルを作成する対象のVPCのIDの指定
  vpc_id = aws_vpc.example.id
  # タグ
  tags = {
    Name = "Terraform検証用 RouteTable-private-a"
  }
}
resource "aws_route_table" "private_c" {
  # ルートテーブルを作成する対象のVPCのIDの指定
  vpc_id = aws_vpc.example.id
  # タグ
  tags = {
    Name = "Terraform検証用 RouteTable-private-c"
  }
}

# プライベートサブネットへのルートテーブルの関連付け
# 関連付けを忘れると、デフォルトルートテーブルが自動的に使用されるが、
# デフォルトルートテーブルの利用はアンチパターンであるため、注意。
resource "aws_route_table_association" "private_a" {
  # サブネット単位でどのルートテーブルを使ってルーティングするかを設定する
  route_table_id = aws_route_table.private_a.id
  subnet_id      = aws_subnet.private_a.id
}
resource "aws_route_table_association" "private_c" {
  # サブネット単位でどのルートテーブルを使ってルーティングするかを設定する
  route_table_id = aws_route_table.private_c.id
  subnet_id      = aws_subnet.private_c.id
}

# NAT Gatewayの作成
# パブリックサブネットに配置したNAT Gateway経由で
# プライベートネットワークからインターネットへのアクセスできるようにする
resource "aws_nat_gateway" "nat_a" {
  # NAT Gatewayを配置するサブネットIDの指定
  subnet_id = aws_subnet.public_a.id
  # NAT Gatewayに静的なパブリックIPアドレスを割り当てる
  allocation_id = aws_eip.nat_a.id
  # NAT GatewayはInternet Gatewayに依存しているため、Internet Gateway作成後に作成
  depends_on = [aws_internet_gateway.igw]
  # タグ
  tags = {
    Name = "Terraform検証用 NATGW-A"
  }
}
resource "aws_nat_gateway" "nat_c" {
  # NAT Gatewayを配置するサブネットIDの指定
  subnet_id = aws_subnet.public_c.id
  # NAT Gatewayに静的なパブリックIPアドレスを割り当てる
  allocation_id = aws_eip.nat_c.id
  # NAT GatewayはInternet Gatewayに依存しているため、Internet Gateway作成後に作成
  depends_on = [aws_internet_gateway.igw]
  # タグ
  tags = {
    Name = "Terraform検証用 NATGW-C"
  }
}

# EIP(Elastic IP Address)の設定
# NAT Gatewayに静的なパブリックIPアドレスを割り当てる
resource "aws_eip" "nat_a" {
  vpc = true
  # EIPはInternet Gatewayに依存するため、Internet Gateway作成後に作成
  depends_on = [aws_internet_gateway.igw]
  # タグ
  tags = {
    Name = "Terraform検証用 EIP-A"
  }
}
resource "aws_eip" "nat_c" {
  vpc = true
  # EIPはInternet Gatewayに依存するため、Internet Gateway作成後に作成
  depends_on = [aws_internet_gateway.igw]
  # タグ
  tags = {
    Name = "Terraform検証用 EIP-C"
  }
}

# ルートの作成
# ルートはルートテーブルの1レコードに該当する
resource "aws_route" "private_a" {
  # 関連付けるルートテーブルを指定
  route_table_id = aws_route_table.private_a.id
  # ルーティングするNAT Gatewayを指定
  nat_gateway_id = aws_nat_gateway.nat_a.id
  # Internet Gateway経由でVPC内からインターネットにデータを流す設定
  destination_cidr_block = "0.0.0.0/0"
}
resource "aws_route" "private_c" {
  # 関連付けるルートテーブルを指定
  route_table_id = aws_route_table.private_c.id
  # ルーティングするNAT Gatewayを指定
  nat_gateway_id = aws_nat_gateway.nat_c.id
  # Internet Gateway経由でVPC内からインターネットにデータを流す設定
  destination_cidr_block = "0.0.0.0/0"
}
