#============================================================
# ECS - クラスター
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
# ECS - タスク定義
#============================================================

# ECSタスクの定義
resource "aws_ecs_task_definition" "ecs_task" {
  # タスク定義名（これにリビジョン番号を付与した名前がタスク定義名となる）
  family = "${var.project_name}-ecs-task-definition"
  # CPUとメモリの設定（選択可能なCPUとメモリの組み合わせは決まっている）
  cpu    = var.ecs_container_vcpu
  memory = var.ecs_container_memory
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
      # コンテナ名
      name = "${var.ecs_container_name}"
      # コンテナイメージ名
      image = "${var.ecs_container_image}"
      # タスク実行に必須かどうか
      essential = true
      # マッピングするコンテナのプロトコルとポート番号
      portMappings = [
        {
          protocol      = "tcp"
          containerPort = 80
        }
      ]
      # CloudWatch Logsへのログの転送設定
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-region        = "ap-northeast-1"
          awslogs-group         = "${aws_cloudwatch_log_group.ecs_task.name}"
          awslogs-stream-prefix = "ecs"
        }
      }
    }
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
resource "aws_iam_role" "task_execution_role" {
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
resource "aws_iam_role" "task_role" {
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
# ECS - CloudWatch Logs
#============================================================

# コンテナのログ保存先をCloudWatch Logsに作成
resource "aws_cloudwatch_log_group" "ecs_task" {
  # ロググループ名の設定
  name = "/ecs/nginx-loggroup"
  # タグ
  tags = {
    Name = var.project_name
  }
}



#============================================================
# ECS - サービス
#============================================================

# ECS サービス
resource "aws_ecs_service" "ecs_service" {
  # ECSサービス名
  name = "${var.project_name}-ecs-service"
  # ECSクラスターの設定
  cluster = aws_ecs_cluster.ecs_cluster.arn
  # ECSタスクの設定
  task_definition = aws_ecs_task_definition.ecs_task.arn
  # ECSサービスが維持するタスク数
  desired_count = 1
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
    security_groups = [aws_security_group.default.id]
    # サブネットの指定
    subnets = [
      aws_subnet.public_a.id,
      aws_subnet.public_c.id,
    ]
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



#============================================================
# ECS - セキュリティグループ
#============================================================

# セキュリティグループの作成
resource "aws_security_group" "default" {
  # セキュリティグループ名
  name = "${var.project_name}-service-sg"
  # セキュリティグループを割り当てるVPCのID
  vpc_id = aws_vpc.example.id
  # 説明
  description = "Terraform Test"
  # タグ
  tags = {
    Name = var.project_name
  }
}

# インバウンドルール(VPC外からインスタンスへのアクセスルール)の追加
resource "aws_security_group_rule" "ingress" {
  # 関連付けるセキュリティグループID
  security_group_id = aws_security_group.default.id
  # typeをingressにすることでインバウンドルールになる
  type = "ingress"
  # 通信を許可するプロトコル/ポート番号/IP
  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  cidr_blocks = [aws_vpc.example.cidr_block]
  # 説明
  description = var.project_name
}

# アウトバウンドルール(インスタンスからVPC外へのアクセスルール)の追加
resource "aws_security_group_rule" "egress" {
  # 関連付けるセキュリティグループID
  security_group_id = aws_security_group.default.id
  # typeをegressにすることでアウトバウンドルールになる
  type = "egress"
  # 追加するルール：すべての通信を許可
  from_port   = 0
  to_port     = 0
  protocol    = "all"
  cidr_blocks = ["0.0.0.0/0"]
  # 説明
  description = var.project_name
}



#============================================================
# SCRIPT作成
#============================================================

# ECS ExecによるECSコンテナログインスクリプトの作成
resource "local_file" "login_ecs_container_script" {
  # 出力先パス
  filename = "./bastion_script/login_ecs_container.sh"
  # 出力ファイルのパーミッション
  file_permission = "0755"
  # 出力ファイルの内容
  content = <<DOC
#!/bin/bash

# ECSタスクのIDの取得
TASK_ID=`aws ecs list-tasks \
  --profile ${var.profile} \
  --region ${var.region} \
  --cluster ${aws_ecs_cluster.ecs_cluster.name} \
  | jq '.taskArns[0]' | sed 's/"//g' | cut -f 3 -d '/'`

# ECS ExecによるECSコンテナログイン
aws ecs execute-command \
  --profile ${var.profile} \
  --region ${var.region} \
  --cluster ${aws_ecs_cluster.ecs_cluster.name} \
  --task $TASK_ID \
  --container ${var.ecs_container_name} \
  --interactive --command "/bin/sh"
DOC
}

# ECSコンテナを開始させるスクリプトの作成
resource "local_file" "start_ecs_container_script" {
  # 出力先パス
  filename = "./bastion_script/start_ecs_container.sh"
  # 出力ファイルのパーミッション
  file_permission = "0755"
  # 出力ファイルの内容
  content = <<DOC
#!/bin/bash

# ECSコンテナの開始
aws ecs update-service \
  --profile ${var.profile} \
  --region ${var.region} \
  --cluster ${aws_ecs_cluster.ecs_cluster.name} \
  --service ${aws_ecs_service.ecs_service.name} \
  --desired-count 1 \
  --no-cli-pager
DOC
}

# ECSコンテナを停止させるスクリプトの作成
resource "local_file" "stop_ecs_container_script" {
  # 出力先パス
  filename = "./bastion_script/stop_ecs_container.sh"
  # 出力ファイルのパーミッション
  file_permission = "0755"
  # 出力ファイルの内容
  content = <<DOC
#!/bin/bash

# ECSコンテナの停止
aws ecs update-service \
  --profile ${var.profile} \
  --region ${var.region} \
  --cluster ${aws_ecs_cluster.ecs_cluster.name} \
  --service ${aws_ecs_service.ecs_service.name} \
  --desired-count 0 \
  --no-cli-pager
DOC
}
