### ECRリポジトリの作成とコンテナイメージのプッシュ

# ローカル変数の定義
locals {
  # コンテナイメージ名
  image_name = "nginx"
  # Dockerfileがあるディレクトリパス
  dockerfile_dir = "./src"
}

# ECRのリポジトリの設定
resource "aws_ecr_repository" "main" {
  # リポジトリ名
  name = local.image_name
  # イメージタグの上書き防止設定(MUTABLE:上書き可/IMMUTABLE:上書き不可)
  image_tag_mutability = "MUTABLE"
  # レジストリにpushしたコンテナイメージのセキュリティスキャン設定
  image_scanning_configuration {
    scan_on_push = true
  }
  # コンテナイメージの暗号化設定
  encryption_configuration {
    encryption_type = "AES256"
  }
  # イメージが含まれていても強制的に削除するか
  force_delete = true
  # タグ
  tags = {
    Name = "Terraform検証用"
  }
}

# ECRリポジトリのライフサイクルの設定
resource "aws_ecr_lifecycle_policy" "main" {
  # ライフサイクルの設定対象リポジトリ名
  repository = aws_ecr_repository.main.name
  # ライフサイクルのルール
  policy = jsonencode({
    rules = [
      {
        description  = "最新イメージを30個だけ残すルール"
        rulePriority = 1
        action = {
          type = "expire"
        }
        selection = {
          countNumber = 30
          countType   = "imageCountMoreThan"
          tagStatus   = "any"
        }
      },
    ]
  })
}

# ローカルで実行するコマンドの設定
resource "null_resource" "main" {
  # ECRリポジトリ作成後に実行
  triggers = {
    trigger = "${aws_ecr_repository.main.id}"
  }
  # 実行コマンド：コンテナイメージのビルドとプッシュ
  provisioner "local-exec" {
    command = "aws ecr get-login-password --region ap-northeast-1 | docker login --username AWS --password-stdin ${aws_ecr_repository.main.repository_url}"
  }
  provisioner "local-exec" {
    command = "docker build -t ${local.image_name} ${local.dockerfile_dir}"
  }
  provisioner "local-exec" {
    command = "docker tag ${local.image_name}:latest ${aws_ecr_repository.main.repository_url}"
  }
  provisioner "local-exec" {
    command = "docker push ${aws_ecr_repository.main.repository_url}"
  }
}
