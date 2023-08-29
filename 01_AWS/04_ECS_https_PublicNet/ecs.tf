#==============================
# ECS
#==============================

# ECSクラスターの定義
resource "aws_ecs_cluster" "example" {
  # クラスター名
  name = "example-terraform-cluster"
  # タグ
  tags = {
    Name = "Terraform検証用"
  }
}

# Task Execution Roleの設定
# Task Execution RoleとはECS上でコンテナを実行するために必要な操作を行うためのIAMロールである。
# Task Execution Roleを使用する主体はコンテナ自体ではなく、ECS Agentである。
# ECRからのコンテナイメージのpull、CloudWatch LogsのLog Streamの作成とログ出力、
# SSMからの値取得などの操作が対象となる。
resource "aws_iam_role" "task_execution_role" {
  # Task Execution Role名の設定
  name = "task_execution_roleution_role"
  # ロールポリシーの設定
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "ecs-tasks.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  ]
}

# Task Roleの設定
# Task RoleとはECS上で稼働するコンテナからAWSサービスを利用する際に必要となるIAMロールである。
# 例：コンテナからのS3操作，DynamoDB操作など
resource "aws_iam_role" "task_role" {
  # Task Role名の設定
  name = "ecs_task_role"
  # ロールポリシーの設定
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "ecs-tasks.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })
  # コンテナから操作を許可するAWSリソースの記述
  inline_policy {
    name = "allow_logs"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        { # CloudWatch Logsへのログ出力許可
          Effect = "Allow"
          Action = [
            "logs:CreateLogStream",
            "logs:DescribeLogGroups",
            "logs:DescribeLogStreams",
            "logs:PutLogEvents",
          ]
          Resource = "*"
        }
      ]
    })
  }
}

# ECSタスクの定義
resource "aws_ecs_task_definition" "example" {
  # タスク定義名（これにリビジョン番号を付与した名前がタスク定義名となる）
  family = "example-terraform-task"
  # CPUとメモリの設定（選択可能なCPUとメモリの組み合わせは決まっている）
  cpu    = "256"  # 0.25vCPU
  memory = "1024" # 1GB
  # Task Execution Roleの設定
  execution_role_arn = aws_iam_role.task_execution_role.arn
  # Task Roleの設定
  task_role_arn = aws_iam_role.task_role.arn
  # 起動タイプの指定
  requires_compatibilities = ["FARGATE"]
  # ネットワークモード（FARGATEの場合はawsvpcを指定）
  network_mode = "awsvpc"
  # コンテナの定義
  container_definitions = jsonencode([
    {
      name      = "nginx"        # コンテナ名
      image     = "nginx:latest" # コンテナイメージ名
      essential = true           # タスク実行に必須かどうか
      portMappings = [           # マッピングするコンテナのプロトコルとポート番号
        {
          protocol      = "tcp"
          containerPort = 80
        }
      ]
      logConfiguration = { # CloudWatch Logsへのログの転送設定
        logDriver = "awslogs"
        options = {
          awslogs-region        = "ap-northeast-1"
          awslogs-group         = "${aws_cloudwatch_log_group.example.name}"
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

# ECS サービス
resource "aws_ecs_service" "example" {
  # ECSサービス名
  name = "example-terraform-service"
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
    assign_public_ip = true
    # セキュリティグループの指定
    security_groups = [module.ecs_service_sg.security_group_id]
    # サブネットの指定
    subnets = [
      aws_subnet.public_a.id,
      aws_subnet.public_c.id,
    ]
  }
  # ロードバランサーの設定
  load_balancer {
    # ターゲットグループとコンテナ名，ポート番号を指定し、ロードバランサーと関連付ける
    target_group_arn = aws_lb_target_group.ecs.arn
    container_name   = "nginx"
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
module "ecs_service_sg" {
  # 利用するモジュールの指定
  source = "./security_group"
  # セキュリティグループ名の指定
  name = "ecs_service_sg"
  # セキュリティグループを割り当てるVPC IDの指定
  vpc_id = aws_vpc.example.id
  # 通信を許可するポート番号/IPの指定
  port        = 80
  cidr_blocks = [aws_vpc.example.cidr_block]
}
