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



#============================================================
# VPCエンドポイント
# VPC内のサービス（Batch, EC2, ECS, Lambdaなど）からNAT Gateway，Internet Gatewayを経由せずに
# VPC外のサービス（CloudWatch Logs, S3など）に直接アクセスさせることで、
# NAT Gateway利用料金の削減、およびセキュリティ向上が見込める。
# [VPCエンドポイントがサポートされているサービス一覧]
# https://docs.aws.amazon.com/ja_jp/vpc/latest/privatelink/aws-services-privatelink-support.html
#============================================================

# VPC内リソースからVPC外リソースにフルアクセスするためのVPCエンドポイントの作成
resource "aws_vpc_endpoint" "s3_endpoint" {
  # 対象となるVPCのID
  vpc_id = aws_vpc.main.id
  # VPCエンドポイント対象サービスのDNSドメイン名（S3の場合はcom.amazonaws.region.s3）
  service_name = "com.amazonaws.${var.region}.s3"
  # VPCエンドポイントのタイプ（Gateway, Interfaceなど）（S3の場合はGateway）
  vpc_endpoint_type = "Gateway"
  # プライベートDNSを有効化するか（true:有効）（VPCエンドポイントのタイプがInterfaceの場合は有効化が必要）
  private_dns_enabled = false
  # プライベートサブネットのルートテーブルにエンドポイントを追加
  route_table_ids = [for value in aws_route_table.private : value.id]
  # タグ
  tags = {
    Name              = "${var.project_name}-s3-vpc-endpoint"
    ProjectName       = var.project_name
    ResourceCreatedBy = "terraform"
  }
}
resource "aws_vpc_endpoint" "cloudwatch_logs_endpoint" {
  # 対象となるVPCのID
  vpc_id = aws_vpc.main.id
  # VPCエンドポイント対象サービスのDNSドメイン名（CloudWatch Logsの場合はcom.amazonaws.region.logs）
  service_name = "com.amazonaws.${var.region}.logs"
  # VPCエンドポイントのタイプ（Gateway, Interfaceなど）（CloudWatch Logsの場合はInterface）
  vpc_endpoint_type = "Interface"
  # プライベートDNSを有効化するか（true:有効）（VPCエンドポイントのタイプがInterfaceの場合は有効化が必要）
  private_dns_enabled = true
  # プライベートサブネットに配置
  subnet_ids = [for value in aws_subnet.private : value.id]
  # セキュリティグループ
  security_group_ids = [aws_security_group.endpoint_sg.id]
  # タグ
  tags = {
    Name              = "${var.project_name}-cloudwatch-logs-vpc-endpoint"
    ProjectName       = var.project_name
    ResourceCreatedBy = "terraform"
  }
}
resource "aws_vpc_endpoint" "secrets_manager_endpoint" {
  # 対象となるVPCのID
  vpc_id = aws_vpc.main.id
  # VPCエンドポイント対象サービスのDNSドメイン名（Secrets Managerの場合はcom.amazonaws.region.secretsmanager）
  service_name = "com.amazonaws.${var.region}.secretsmanager"
  # VPCエンドポイントのタイプ（Gateway, Interfaceなど）（Secrets Managerの場合はInterface）
  vpc_endpoint_type = "Interface"
  # プライベートDNSを有効化するか（true:有効）（VPCエンドポイントのタイプがInterfaceの場合は有効化が必要）
  private_dns_enabled = true
  # プライベートサブネットに配置
  subnet_ids = [for value in aws_subnet.private : value.id]
  # セキュリティグループ
  security_group_ids = [aws_security_group.endpoint_sg.id]
  # タグ
  tags = {
    Name              = "${var.project_name}-secrets-manager-vpc-endpoint"
    ProjectName       = var.project_name
    ResourceCreatedBy = "terraform"
  }
}



#============================================================
# Security Group
#============================================================

# VPCエンドポイント用のセキュリティグループ
resource "aws_security_group" "endpoint_sg" {
  # セキュリティグループ名
  name = "${var.project_name}-vpc-endpoint-sg"
  # 適用先のVPC
  vpc_id = aws_vpc.main.id
  # インバウントルールの設定（外部からこのセキュリティグループに所属するリソースへのアクセス許可設定）
  ingress {
    # 許可する開始ポート番号
    from_port = 443
    # 許可する終了ポート番号
    to_port = 443
    # 使用するプロトコル（tcpはhttpsの通信プロトコル）
    protocol = "tcp"
    # アクセスを許可する送信元IPアドレスの範囲
    # このVPC内のすべてのIPアドレスを指定することで、このVPC内のLambdaなどのすべてのリソースからアクセスを許可する。
    cidr_blocks = [aws_vpc.main.cidr_block]
    # 説明
    description = "Allow HTTPS from VPC"
  }
  # アウトバウンドルールの設定（このセキュリティグループに所属するリソースから外部へのアクセス許可設定）
  egress {
    # 許可する開始ポート番号（0はすべてのポート番号を許可）
    from_port = 0
    # 許可する終了ポート番号（0はすべてのポート番号を許可）
    to_port = 0
    # 使用するプロトコル（-1はすべてのプロトコルを許可）
    protocol = "-1"
    # アクセスを許可する送信先のIPアドレスの範囲
    # 0.0.0.0/0を指定することで、インターネット上のすべてのIPアドレスへのアクセスを許可する。
    cidr_blocks = ["0.0.0.0/0"]
    # 説明
    description = "Allow all outbound"
  }
  # セキュリティグループの説明
  description = "${var.project_name} VPC Endpoint Security Group"
  # タグ
  tags = {
    Name              = "${var.project_name}-vpc-endpoint-sg"
    ProjectName       = var.project_name
    ResourceCreatedBy = "terraform"
  }
}
