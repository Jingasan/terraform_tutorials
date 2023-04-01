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
    security_groups = [module.nginx_sg.security_group_id]
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

# セキュリティグループの作成(HTTP 80番ポートの許可)
module "nginx_sg" {
  # 利用するモジュールの指定
  source = "./security_group"
  # セキュリティグループ名の指定
  name = "nginx-sg"
  # セキュリティグループを割り当てるVPC IDの指定
  vpc_id = aws_vpc.example.id
  # 通信を許可するポート番号/IPの指定
  port        = 80
  cidr_blocks = [aws_vpc.example.cidr_block]
}
