#==============================
# ECS
#==============================

# ECSクラスターの定義
resource "aws_ecs_cluster" "example" {
  # クラスター名
  name = "example-cluster"
  # タグ
  tags = {
    Name = "Terraform検証用"
  }
}

# ECSタスクの定義
resource "aws_ecs_task_definition" "example" {
  # タスク定義名（これにリビジョン番号を付与した名前がタスク定義名となる）
  family = "example-task"
  # CPUとメモリの設定（選択可能なCPUとメモリの組み合わせは決まっている）
  cpu    = "256"  # 0.25vCPU
  memory = "1024" # 1GB
  # 起動タイプの指定
  requires_compatibilities = ["FARGATE"]
  # ネットワークモード（FARGATEの場合はawsvpcを指定）
  network_mode = "awsvpc"
  # コンテナの定義
  container_definitions = jsonencode([
    {
      "name" : "example",       # コンテナ名
      "image" : "nginx:latest", # コンテナイメージ名
      "essential" : true,       # タスク実行に必須かどうか
      "portMappings" : [        # マッピングするコンテナのプロトコルとポート番号
        {
          "protocol" : "tcp",
          "containerPort" : 80
        }
      ]
    }
  ])
}

# ECS サービス
resource "aws_ecs_service" "example" {
  # ECSサービス名
  name = "example"
  # ECSクラスターの設定
  cluster = aws_ecs_cluster.example.arn
  # ECSタスクの設定
  task_definition = aws_ecs_task_definition.example.arn
  # ECSサービスが維持するタスク数
  desired_count = 2
  # 起動タイプ
  launch_type = "FARGATE"
  # FARGATEプラットフォームのバージョン
  # https://docs.aws.amazon.com/ja_jp/AmazonECS/latest/developerguide/platform_versions.html
  platform_version = "1.4.0"
  # タスク起動時のヘルスチェック猶予時間(秒)
  health_check_grace_period_seconds = 60
  # ネットワーク設定
  network_configuration {
    # パブリックIPアドレスを割り当てるかどうか
    assign_public_ip = false
    # セキュリティグループの指定
    security_groups = [aws_security_group.nginx_sg.id]
    # サブネットの指定
    subnets = [
      aws_subnet.private_a.id,
      aws_subnet.private_c.id,
    ]
  }
  # ロードバランサーの設定
  load_balancer {
    # ターゲットグループとコンテナ名，ポート番号を指定し、ロードバランサーと関連付ける
    target_group_arn = aws_lb_target_group.ecs.arn
    container_name   = "example"
    container_port   = 80
  }
  # ECSサービスのライフサイクル設定
  lifecycle {
    # FARGATEではデプロイの度にタスク定義が更新されるため、
    # タスク定義の変更の度にECSサービスが再デプロイされることを防ぐ
    ignore_changes = [task_definition]
  }
}


#==============================
# セキュリティグループ
#==============================

# セキュリティグループの作成
resource "aws_security_group" "nginx_sg" {
  # セキュリティグループ名
  name = "nginx_sg"
  # セキュリティグループを割り当てるVPCのID
  vpc_id = aws_vpc.example.id
  # 説明
  description = "Terraform Test"
  # タグ
  tags = {
    Name = "Terraform検証用"
  }
}

# インバウンドルール(VPC外からインスタンスへのアクセスルール)の追加
resource "aws_security_group_rule" "nginx_sg_ingress" {
  # 関連付けるセキュリティグループID
  security_group_id = aws_security_group.nginx_sg.id
  # typeをingressにすることでインバウンドルールになる
  type = "ingress"
  # 追加するルール：HTTP通信の許可
  from_port   = "80"
  to_port     = "80"
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  # 説明
  description = "Terraform Test"
}

# アウトバウンドルール(インスタンスからVPC外へのアクセスルール)の追加
resource "aws_security_group_rule" "nginx_sg_egress" {
  # 関連付けるセキュリティグループID
  security_group_id = aws_security_group.nginx_sg.id
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

