#============================================================
# ECSクラスター（RDS接続用の踏み台サーバー）
#============================================================

# ECSクラスターの作成
resource "aws_ecs_cluster" "ecs_cluster" {
  # クラスター名
  name = "${var.project_name}-cluster"
  # ContainerInsightsの有効化
  setting {
    name  = "containerInsights"
    value = "disabled"
  }
  # タグ
  tags = {
    Name = var.project_name
  }
}

# ECSキャパシティープロバイダーの設定
# https://docs.aws.amazon.com/ja_jp/AmazonECS/latest/developerguide/cluster-capacity-providers.html
resource "aws_ecs_cluster_capacity_providers" "ecs_cluster_capacity_providers" {
  # 設定対象のECSクラスター名
  cluster_name = aws_ecs_cluster.ecs_cluster.name
  # キャパシティープロバイダーの選択（FARGATE or EC2）
  capacity_providers = ["FARGATE"]
  # デフォルトのキャパシティープロバイダー戦略
  default_capacity_provider_strategy {
    capacity_provider = "FARGATE"
  }
}



#============================================================
# ECSタスク定義（RDS接続用の踏み台サーバー）
#============================================================

# ECSタスク定義
resource "aws_ecs_task_definition" "ecs_task_definition" {
  # ECSタスク定義名（これにリビジョン番号を付与した名前がタスク定義名となる）
  family = "${var.project_name}-ecs-task-definition"
  # CPUとメモリの設定（選択可能なCPUとメモリの組み合わせは決まっている）
  cpu    = var.ecs_container_vcpu   # 0.25vCPU
  memory = var.ecs_container_memory # 512MB
  # Task Execution Roleの設定
  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
  # Task Roleの設定
  task_role_arn = aws_iam_role.ecs_task_role.arn
  # ネットワークモード（FARGATEの場合はawsvpcを指定）
  network_mode = "awsvpc"
  # 起動タイプの指定
  requires_compatibilities = ["FARGATE"]
  # コンテナの定義
  container_definitions = jsonencode([
    {
      # コンテナ名
      name = "${var.ecs_container_name}"
      # コンテナイメージ名
      image = "${var.ecs_container_image}"
      # タスク実行に必須かどうか
      essential = true
      # tty:true
      pseudoTerminal = true
      # CloudWatch Logsへのログの転送設定
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-region        = "${var.region}"
          awslogs-group         = "${aws_cloudwatch_log_group.service.name}"
          awslogs-stream-prefix = "ecs"
        }
      }
    },
  ])
  # タグ
  tags = {
    Name = var.project_name
  }
}

# Task Execution Roleの設定
# Task Execution RoleとはECS上でコンテナを実行するために必要な操作を行うためのIAMロールである。
# Task Execution Roleを使用する主体はコンテナ自体ではなく、ECS Agentである。
# ECRからのコンテナイメージのpull、CloudWatch LogsのLog Streamの作成とログ出力、
# SSMからの値取得などの操作が対象となる。
resource "aws_iam_role" "ecs_task_execution_role" {
  # Task Execution Role名の設定
  name = "${var.project_name}-ecs-task-execution-role"
  # ロールポリシーの設定
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = ""
        Effect    = "Allow"
        Principal = { Service = "ecs-tasks.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  ]
  # 説明
  description = "${var.project_name} ECS Task Execution Role"
  # タグ
  tags = {
    Name = var.project_name
  }
}

# Task Roleの設定
# Task RoleとはECS上で稼働するコンテナからAWSサービスを利用する際に必要となるIAMロールである。
# 例：コンテナからのS3操作，DynamoDB操作など
resource "aws_iam_role" "ecs_task_role" {
  # Task Role名の設定
  name = "${var.project_name}-ecs-task-role"
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
    name = "ecs_container_policy"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            # Session Managerの利用許可
            "ssmmessages:CreateControlChannel",
            "ssmmessages:CreateDataChannel",
            "ssmmessages:OpenControlChannel",
            "ssmmessages:OpenDataChannel",
            # CloudWatch Logsへのログ出力許可
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
  # 説明
  description = "${var.project_name} ECS Task Role"
  # タグ
  tags = {
    Name = var.project_name
  }
}



#============================================================
# ECSサービス（RDS接続用の踏み台サーバー）
#============================================================

# ECSサービスの作成
resource "aws_ecs_service" "ecs_service" {
  # ECSサービス名
  name = "${var.project_name}-ecs-service"
  # ECSサービスを割り当てるECSクラスター名
  cluster = aws_ecs_cluster.ecs_cluster.arn
  # 割り当てるタスク定義
  task_definition = aws_ecs_task_definition.ecs_task_definition.arn
  # ECSサービスが維持するタスク数
  desired_count = 0
  # 起動タイプ
  launch_type = "FARGATE"
  # FARGATEプラットフォームのバージョン
  # https://docs.aws.amazon.com/ja_jp/AmazonECS/latest/developerguide/platform_versions.html
  platform_version = "LATEST"
  # ecs execの有効化：Session Manager経由でコンテナにアクセスするために必要
  enable_execute_command = true
  # ネットワーク設定
  network_configuration {
    # パブリックIPアドレスを割り当てるかどうか
    assign_public_ip = true
    # セキュリティグループの指定
    security_groups = [aws_security_group.ecs_security_group.id]
    # サブネットの指定
    subnets = [for value in aws_subnet.public : value.id]
  }
  # ECSサービスのライフサイクル設定
  lifecycle {
    # FARGATEではデプロイの度にタスク定義が更新されるため、
    # タスク定義の変更の度にECSサービスが再デプロイされることを防ぐ
    ignore_changes = [task_definition]
  }
  # タグ
  tags = {
    Name = var.project_name
  }
}

# セキュリティグループ
resource "aws_security_group" "ecs_security_group" {
  # セキュリティグループ名
  name = "${var.project_name}-ecs-sg"
  # セキュリティグループの説明
  description = "${var.project_name} ecs sg"
  # 適用先のVPC
  vpc_id = aws_vpc.default.id
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # タグ
  tags = {
    Name = "${var.project_name}-ecs-sg"
  }
}



#============================================================
# CloudWatch Logs
#============================================================

# コンテナのログ保存先をCloudWatch Logsに作成
resource "aws_cloudwatch_log_group" "service" {
  # ロググループ名の設定
  name = "/ecs/${var.project_name}-loggroup"
  # タグ
  tags = {
    "Name" = var.project_name
  }
}



#============================================================
# SCRIPT作成
#============================================================

# SessionManagerによるRDS接続開始スクリプト出力
resource "local_file" "rds_connection_script" {
  # 出力先
  filename = "./bastion_script/establish_rds_connection.sh"
  # 出力ファイルのパーミッション
  file_permission = "0755"
  # 出力ファイルの内容
  content = <<DOC
#!/bin/bash
# ローカルPCからのRDS接続確立用のスクリプト

#============================================================
# 踏み台用のECSコンテナの開始関数
#============================================================
function start_container () {
  echo "---------------------------------------------"
  echo "1. Start bastion container"
  echo "---------------------------------------------"
  # 踏み台用のECSコンテナの開始
  aws ecs update-service \
    --profile ${var.profile} \
    --region ${var.region} \
    --cluster ${aws_ecs_cluster.ecs_cluster.name} \
    --service ${aws_ecs_service.ecs_service.name} \
    --desired-count 1 \
    --no-cli-pager > /dev/null 2>&1
}

#============================================================
# Session ManagerによるRDS接続の開始関数
#============================================================
function start_rds_connection () {
  echo "---------------------------------------------"
  echo "2. Start RDS connection with Session Manager"
  echo "---------------------------------------------"

  # ECSタスクのIDの取得
  while :
  do
    sleep 3
    TASK_ID=`aws ecs list-tasks \
      --profile ${var.profile} \
      --region ${var.region} \
      --cluster ${aws_ecs_cluster.ecs_cluster.name} \
      | jq '.taskArns[0]' | sed 's/"//g' | cut -f 3 -d '/'`
    if [ x"$TASK_ID" != x"null" ]; then
      break
    fi
  done
  echo "Container Task ID: $TASK_ID"

  # ECSタスクのラインタイムIDの取得
  while :
  do
    sleep 3
    RUNTIME_ID=`aws ecs describe-tasks \
      --profile ${var.profile} \
      --region ${var.region} \
      --cluster ${aws_ecs_cluster.ecs_cluster.name} \
      --task $TASK_ID | jq '.tasks[0].containers[0].runtimeId' | sed 's/"//g'`
    if [ x"$RUNTIME_ID" != x"null" ]; then
      break
    fi
  done
  echo "ECS Runtime ID: $RUNTIME_ID"

  # すぐに繋ぐとエラーとなるため、待機
  sleep 5

  # Session ManagerによるRDS接続の開始
  aws ssm start-session \
    --profile ${var.profile} \
    --region ${var.region} \
    --target "ecs:${aws_ecs_cluster.ecs_cluster.name}_"$TASK_ID"_"$RUNTIME_ID \
    --document-name AWS-StartPortForwardingSessionToRemoteHost \
    --parameters '{"host":["${aws_db_instance.rds.address}"],"portNumber":["${aws_db_instance.rds.port}"], "localPortNumber":["${aws_db_instance.rds.port}"]}'
}

#============================================================
# 踏み台用のECSコンテナの終了関数
#============================================================
function stop_container () {
  echo "---------------------------------------------"
  echo "3. Stop bastion container"
  echo "---------------------------------------------"
  # 踏み台用のECSコンテナの停止
  aws ecs update-service \
    --profile ${var.profile} \
    --region ${var.region} \
    --cluster ${aws_ecs_cluster.ecs_cluster.name} \
    --service ${aws_ecs_service.ecs_service.name} \
    --desired-count 0 \
    --no-cli-pager > /dev/null 2>&1
  exit 1
}

#============================================================
# メイン処理
#============================================================

# Ctrl+Cなどで終了したらECSコンテナを終了する処理をトリガー
trap 'stop_container' {1,2,9,20}

# 踏み台用のECSコンテナの開始
start_container

# Session ManagerによるRDS接続の開始
start_rds_connection

# 踏み台用のECSコンテナの終了
stop_container

DOC
}
