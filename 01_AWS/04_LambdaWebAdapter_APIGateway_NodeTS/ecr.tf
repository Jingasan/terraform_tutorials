#============================================================
# ECR - Lambdaのコンテナイメージ用
#============================================================

# ECRリポジトリの設定
resource "aws_ecr_repository" "lambda" {
  # リポジトリ名
  name = "${var.project_name}-lambda-web-adapter-express-${local.lower_random_hex}"
  # イメージタグの上書き防止設定（MUTABLE:上書き可/IMMUTABLE:上書き不可）
  image_tag_mutability = "MUTABLE"
  # コンテナイメージのセキュリティスキャン設定
  image_scanning_configuration {
    # プッシュ時にセキュリティスキャンを実行するか（true:実行）
    scan_on_push = true
  }
  # コンテナイメージの暗号化設定
  encryption_configuration {
    # 暗号化の種類
    encryption_type = "AES256"
  }
  # イメージが含まれていても強制的に削除するか（true:強制削除）
  force_delete = true
  # タグ
  tags = {
    Name = var.project_name
  }
}

# ECRリポジトリのライフサイクル設定
resource "aws_ecr_lifecycle_policy" "lambda" {
  # ライフサイクルの設定対象リポジトリ名
  repository = aws_ecr_repository.lambda.name
  # ライフサイクルのルール
  policy = jsonencode({
    rules = [
      {
        description  = "最新イメージを1個だけ残すルール"
        rulePriority = 1
        action = {
          type = "expire"
        }
        selection = {
          countNumber = 1
          countType   = "imageCountMoreThan"
          tagStatus   = "any"
        }
      },
    ]
  })
}

# ECRにコンテナイメージをプッシュするスクリプト出力
resource "local_file" "ecr" {
  # 出力先
  filename = "./script/deploy_lambda_container_image.sh"
  # 出力ファイルのパーミッション
  file_permission = "0755"
  # 出力ファイルの内容
  content = <<DOC
#!/bin/bash
# ECRにコンテナイメージをプッシュするスクリプト（自動生成）

# 本スクリプトのあるディレクトリに移動
THIS_SCRIPT_DIR="$(cd "$(dirname "$BASH_SOURCE[0]")" && pwd)"
pushd $THIS_SCRIPT_DIR > /dev/null 2>&1

# Dockerfileがあるディレクトリに移動
pushd ../docker > /dev/null 2>&1
# コンテナイメージリポジトリへのログイン
aws ecr get-login-password --region ${var.region} --profile ${var.profile} | docker login --username AWS --password-stdin ${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com
# コンテナイメージのビルド
docker build -t ${aws_ecr_repository.lambda.repository_url}:latest -f Dockerfile .
# コンテナイメージのプッシュ
docker push ${aws_ecr_repository.lambda.repository_url}:latest
# 元のディレクトリに戻る
popd > /dev/null 2>&1

# 元のディレクトリに戻る
popd > /dev/null 2>&1
DOC
}

# コンテナイメージのビルドとプッシュ
resource "null_resource" "ecr" {
  # ECRにコンテナイメージをビルド／プッシュするスクリプトの作成後に実行
  depends_on = [local_file.ecr]
  # 各種ジョブコンテナイメージのビルドとデプロイ
  provisioner "local-exec" {
    # 実行するコマンド
    command = "bash ${local_file.ecr.filename} ${var.profile}"
    # コマンドを実行するディレクトリ
    working_dir = "."
  }
}
