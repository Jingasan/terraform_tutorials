#============================================================
# Batch - Computing Environment
#============================================================

# コンピューティング環境の作成
locals {
  public_subnet_ids  = [for value in aws_subnet.public : value.id]
  private_subnet_ids = [for value in aws_subnet.private : value.id]
}
resource "aws_batch_compute_environment" "aws-batch-computing-environment" {
  # AWS Batchの実行ロールが生成されてからコンピューティング環境を作成
  depends_on = [
    aws_iam_role_policy_attachment.batch-compute-environment
  ]
  # コンピューティング環境名
  compute_environment_name = var.project_name
  # サービスロール
  service_role = aws_iam_role.batch-compute-environment.arn
  # タイプ
  type = "MANAGED"
  # コンピューティング環境を有効化
  state = "ENABLED"
  # コンピューティングリソースの設定
  compute_resources {
    # コンピューティング環境の種類（FARGATE/FARGATE_SPOT/EC2/SPOT）
    type = "FARGATE"
    # 最大vCPU数（ジョブの同時実行数=最大vCPU数/ジョブ1つのvCPU数）
    max_vcpus = var.batch_max_vcpus
    # VPCサブネット
    subnets = concat(
      local.public_subnet_ids,
      local.private_subnet_ids
    )
    # VPCセキュリティグループ
    security_group_ids = [
      aws_security_group.batch.id
    ]
  }
  # タグ
  tags = {
    Name = var.project_name
  }
}

# コンピューティング環境に割り当てるIAMロールの作成
resource "aws_iam_role" "batch-compute-environment" {
  # IAMロール名
  name = "${var.project_name}-aws-batch-service-role"
  # ロールポリシー
  assume_role_policy = data.aws_iam_policy_document.batch-compute-environment-assume.json
}

# AWS Batchサービスに対してIAMロールの割り当てを許可
data "aws_iam_policy_document" "batch-compute-environment-assume" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["batch.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

# IAMロールに対するポリシーの割り当て
resource "aws_iam_role_policy_attachment" "batch-compute-environment" {
  # 割り当て先のIAMロール名
  role = aws_iam_role.batch-compute-environment.name
  # 割り当てるポリシー：AWS Batchの実行ロール
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBatchServiceRole"
}

# コンピューティング環境に割り当てるセキュリティグループ
resource "aws_security_group" "batch" {
  # セキュリティグループ名
  name = "${var.project_name}-batch-sg"
  # セキュリティグループの説明
  description = "Security Group for AWS Batch"
  # 適用先のVPC
  vpc_id = aws_vpc.default.id
  # タグ
  tags = {
    Name = var.project_name
  }
}

# アウトバウンドルールの追加
resource "aws_security_group_rule" "batch_egress_all" {
  # 割り当て先のセキュリティグループID
  security_group_id = aws_security_group.batch.id
  # typeをegressにすることでアウトバウンドルールになる
  type = "egress"
  # すべての通信を許可
  from_port   = 0
  to_port     = 0
  protocol    = "all"
  cidr_blocks = ["0.0.0.0/0"]
  # 説明
  description = "${var.project_name} aws batch sgr"
}



#============================================================
# Batch - Job Queue
#============================================================

# ジョブキューの作成
resource "aws_batch_job_queue" "job_queue" {
  # ジョブキュー名
  name = var.project_name
  # ジョブキューを有効化
  state = "ENABLED"
  # ジョブキューの優先度
  priority = 1
  # 接続されたコンピューティング環境（最低１つ最大３つ指定可能）
  compute_environments = [
    aws_batch_compute_environment.aws-batch-computing-environment.arn,
  ]
  # タグ
  tags = {
    Name = var.project_name
  }
}



#============================================================
# Batch - Job Definition
#============================================================

# ジョブ定義の作成
resource "aws_batch_job_definition" "job_definition" {
  # ジョブ定義名
  name = var.project_name
  # ジョブ定義のタイプ
  type = "container"
  # オーケストレーションタイプ(FARGATE/EC2)
  platform_capabilities = [
    "FARGATE",
  ]
  # 実行タイムアウト設定(Default:タイムアウトなし)
  # timeout {
  #   # 未完了のジョブを強制終了するまでの時間[sec](Minimum:60)
  #   attempt_duration_seconds = 60
  # }
  # コンテナの設定
  # https://docs.aws.amazon.com/batch/latest/APIReference/API_RegisterJobDefinition.html
  container_properties = jsonencode({
    # Fargateプラットフォームの設定
    fargatePlatformConfiguration = {
      # FARGATEプラットフォームのバージョン
      platformVersion = "LATEST"
    }
    # ランタイムプラットフォーム
    runtimePlatform = {
      # OSファミリー(Linux／Windows)
      operatingSystemFamily = "LINUX"
      # CPUアーキテクチャー
      cpuArchitecture = "X86_64",
    }
    # ネットワーク設定
    networkConfiguration = {
      # パブリックIPの割り当て(ENABLED/DISABLED)
      assignPublicIp = "ENABLED"
    }
    # エフェメラルストレージの割り当て(Default:20GB)
    # ephemeralStorage = {
    #   # 割り当てサイズ[GB](設定可能値：21-200)
    #   sizeInGiB = 21
    # }
    # ECSタスクの実行ロール
    executionRoleArn = "${aws_iam_role.taskexecution.arn}"
    # ジョブに割り当てる他のAWSサービスの操作権限
    jobRoleArn = "${aws_iam_role.batch_job.arn}"
    # コンテナイメージ
    image = "${aws_ecr_repository.batch.repository_url}"
    # コマンド
    command = "${var.batch_commands}"
    # 環境設定
    resourceRequirements = [
      # vCPU数
      {
        type  = "VCPU"
        value = "${var.batch_vcpu}"
      },
      # メモリサイズ(MB)
      {
        type  = "MEMORY"
        value = "${var.batch_memory}"
      }
    ]
    # デフォルトの環境変数の指定
    environment = [
      {
        name  = "ENV",
        value = "VALUE"
      },
    ]
    # ログの出力設定
    logConfiguration = {
      # ログの出力先をCloudWatchに設定
      logDriver     = "awslogs"
      secretOptions = null
      options = {
        # CloudWatch Logsのロググループ名
        awslogs-group = "${aws_cloudwatch_log_group.batch_job_loggroup.name}"
        # ログのリージョン
        awslogs-region = "${var.region}"
        # Prefix
        awslogs-stream-prefix = "job"
      }
    }
  })
  # タグ
  tags = {
    Name = var.project_name
  }
}

# ジョブに割り当てるAWSサービス操作権限のIAMロール作成
resource "aws_iam_role" "batch_job" {
  # IAMロール名
  name = "${var.project_name}-iam-role-for-ecs-batch-task"
  # IAMロールの対象となるAWSサービスの指定
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      },
    ]
  })
  # 説明
  description = "${var.project_name} IAM Role for ECS Batch Task"
  # タグ
  tags = {
    Name = var.project_name
  }
}

# Batchで実行されるECSタスクのIAMロールポリシー設定
resource "aws_iam_role_policy" "batch_job" {
  # ポリシー名
  name = "${var.project_name}-ecs-bacth-job-iam-policy"
  # 割り当て先のIAMロール名
  role = aws_iam_role.batch_job.id
  # ポリシー(どのAWSリソースにどのような操作を許可するか)の定義
  policy = data.aws_iam_policy_document.batch_job_custom.json
}

# Batchで実行されるECSタスクに割り当てるポリシー(どのAWSリソースにどのような操作を許可するか)の定義
data "aws_iam_policy_document" "batch_job_custom" {
  version = "2012-10-17"
  statement {
    effect = "Allow"
    # 許可する操作の指定
    actions = [
      "s3:*",             # S3関連のすべての操作権限
      "rds:*",            # RDS関連のすべての操作権限
      "secretsmanager:*", # Secrets Manager関連のすべての操作権限
      "logs:*",           # CloudWatch Logs関連のすべての操作権限
    ]
    # 対象となるAWSリソースのARNの指定
    resources = [
      "*",
    ]
  }
}

# ジョブ定義に割り当てるECSタスク（ジョブ）実行権限のIAMロール作成
resource "aws_iam_role" "taskexecution" {
  # IAMロール名
  name = "${var.project_name}-task-execution-role-for-batch-definition"
  # ロールポリシー
  assume_role_policy = data.aws_iam_policy_document.taskexecution_assume.json
}

# ECSサービスに対してIAMロールの割り当てを許可
data "aws_iam_policy_document" "taskexecution_assume" {
  statement {
    effect = "Allow"
    actions = [
      "sts:AssumeRole",
    ]
    principals {
      type = "Service"
      identifiers = [
        "ecs-tasks.amazonaws.com",
      ]
    }
  }
}

# IAMロールに対するポリシーの割り当て
resource "aws_iam_role_policy_attachment" "taskexecution" {
  # 割り当て先のサービスロール名
  role = aws_iam_role.taskexecution.id
  # 割り当てるポリシー：ECSタスクの実行ロール
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}



#============================================================
# Batch - CloudWatch Logs
#============================================================

# CloudWatchロググループの設定
resource "aws_cloudwatch_log_group" "batch_job_loggroup" {
  # CloudWatchロググループ名
  name = "/aws/batch/${var.project_name}"
  # CloudWatchにログを残す期間（日）
  retention_in_days = var.batch_cloudwatch_log_retention_in_days
  # タグ
  tags = {
    Name = var.project_name
  }
}
