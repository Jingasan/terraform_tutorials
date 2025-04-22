#============================================================
# VPC
#============================================================

# VPCの作成
resource "aws_vpc" "main" {
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
    Name              = "${var.project_name}-vpc"
    ProjectName       = var.project_name
    ResourceCreatedBy = "terraform"
  }
}



#============================================================
# パブリックサブネット
#============================================================

locals {
  azs = ["${var.region}a", "${var.region}c", "${var.region}d"]
}

# パブリックサブネットの作成
resource "aws_subnet" "public" {
  # 作成するパブリックサブネット数
  count = 2
  # サブネットを作成する対象のVPCのIDの指定
  vpc_id = aws_vpc.main.id
  # IPv4アドレスの範囲指定（CIDRを8bit分割したIPの中から指定）
  cidr_block = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index)
  # サブネットを作成するアベイラビリティゾーンの指定
  # アベイラビリティゾーンをまたがったサブネットは作成できない
  availability_zone = local.azs[count.index]
  # そのサブネットで起動したインスタンスにパブリックIPを自動で割り当てる
  map_public_ip_on_launch = true
  # タグ
  tags = {
    Name              = "${var.project_name}-public-subnet-${count.index}"
    ProjectName       = var.project_name
    ResourceCreatedBy = "terraform"
  }
}

# Internet Gatewayの作成
resource "aws_internet_gateway" "igw" {
  # Internet Gateway作成対象のVPC IDの指定
  vpc_id = aws_vpc.main.id
  # タグ
  tags = {
    Name              = "${var.project_name}-igw"
    ProjectName       = var.project_name
    ResourceCreatedBy = "terraform"
  }
}

# パブリックサブネット用のルートテーブルの作成
resource "aws_route_table" "public" {
  # ルートテーブルを作成する対象のVPCのIDの指定
  vpc_id = aws_vpc.main.id
  # Internet Gateway経由でVPC内からインターネットにデータを流すルートの作成
  route {
    # すべてのIPv4アドレス（インターネットアクセス）へのトラフィックを対象とする
    cidr_block = "0.0.0.0/0"
    # インターネットゲートウェイ（IGW）IDの指定
    # このルートテーブルが紐付けられているパブリックサブネット内のリソースがIGW経由でインターネットにアクセス可能になる。
    gateway_id = aws_internet_gateway.igw.id
  }
  # タグ
  tags = {
    Name              = "${var.project_name}-public-rt"
    ProjectName       = var.project_name
    ResourceCreatedBy = "terraform"
  }
}

# 各パブリックサブネットへのルートテーブルの関連付け
# 関連付けを忘れると、デフォルトルートテーブルが自動的に使用されるが、
# デフォルトルートテーブルの利用はアンチパターンであるため、注意。
resource "aws_route_table_association" "public" {
  # サブネットIDの指定（すべてのパブリックサブネットをルートテーブルに紐付ける）
  count     = length(aws_subnet.public)
  subnet_id = aws_subnet.public[count.index].id
  # ルートテーブルの指定
  route_table_id = aws_route_table.public.id
}

# EIP（Elastic IP Address）の設定
# NAT Gatewayに静的なパブリックIPアドレスを割り当てる
resource "aws_eip" "nat" {
  count = length(aws_subnet.public)
  # EIPはInternet Gatewayに依存するため、Internet Gateway作成後に作成
  depends_on = [aws_internet_gateway.igw]
  # EIPをVPCで利用する場合に指定
  domain = "vpc"
  # タグ
  tags = {
    Name              = "${var.project_name}-eip-${count.index}"
    ProjectName       = var.project_name
    ResourceCreatedBy = "terraform"
  }
}

# NAT Gatewayの作成（マルチAZ対応の為、各パブリックサブネットに作成する）
# パブリックサブネットに配置したNAT Gateway経由で
# プライベートサブネット内のリソースからインターネットにアクセスできるようになる。
# VPC外のAWSリソースへのアクセスにはVPCエンドポイント経由でアクセスすることで、
# NAT Gatewayの利用料金を削減、およびセキュリティを向上させる。
resource "aws_nat_gateway" "ngw" {
  count = length(aws_subnet.public)
  # NAT GatewayはInternet Gatewayに依存しているため、Internet Gateway作成後に作成
  depends_on = [aws_internet_gateway.igw]
  # NAT Gatewayを配置するサブネットIDの指定
  subnet_id = aws_subnet.public[count.index].id
  # NAT Gatewayに静的なパブリックIPアドレスを割り当てる
  allocation_id = aws_eip.nat[count.index].id
  # タグ
  tags = {
    Name              = "${var.project_name}-ngw-${count.index}"
    ProjectName       = var.project_name
    ResourceCreatedBy = "terraform"
  }
}



#============================================================
# プライベートサブネット
#============================================================

# プライベートサブネットの作成
resource "aws_subnet" "private" {
  # プライベートサブネット数
  count = 3
  # サブネットを作成する対象のVPCのIDの指定
  vpc_id = aws_vpc.main.id
  # IPv4アドレスの範囲指定（CIDRを8bit分割したIPの中から指定）
  cidr_block = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index + 10)
  # サブネットを作成するアベイラビリティゾーンの指定
  # アベイラビリティゾーンをまたがったサブネットは作成できない
  availability_zone = local.azs[count.index]
  # タグ
  tags = {
    Name              = "${var.project_name}-private-subnet-${count.index}"
    ProjectName       = var.project_name
    ResourceCreatedBy = "terraform"
  }
}

# プライベートサブネット用のルートテーブルの作成
resource "aws_route_table" "private" {
  count = length(aws_nat_gateway.ngw)
  # ルートテーブルを作成する対象のVPCのIDの指定
  vpc_id = aws_vpc.main.id
  # NAT Gateway経由でプライベートサブネット内からインターネットにデータを流すルート（アウトバウンド通信）の作成
  route {
    # すべてのIPv4アドレス（インターネットアクセス）へのトラフィックを対象とする
    cidr_block = "0.0.0.0/0"
    # NAT Gateway IDの指定
    # このルートテーブルが紐付けられているプライベートサブネット内のリソースがNAT Gateway経由のIGW経由でインターネットにアクセス可能になる。
    nat_gateway_id = aws_nat_gateway.ngw[count.index].id
  }
  # タグ
  tags = {
    Name              = "${var.project_name}-private-rt-${count.index}"
    ProjectName       = var.project_name
    ResourceCreatedBy = "terraform"
  }
}

# プライベートサブネットへのルートテーブルの関連付け
# 関連付けを忘れると、デフォルトルートテーブルが自動的に使用されるが、
# デフォルトルートテーブルの利用はアンチパターンであるため、注意。
resource "aws_route_table_association" "private" {
  # サブネットIDの指定（すべてのプライベートサブネットをルートテーブルに紐付ける）
  count     = length(aws_subnet.private)
  subnet_id = aws_subnet.private[count.index].id
  # ルートテーブルの指定
  route_table_id = aws_route_table.private[count.index % length(aws_route_table.private)].id
}
