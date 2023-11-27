#============================================================
# Code Artifact
#============================================================

# リポジトリの作成
resource "aws_codeartifact_repository" "repo" {
  # リポジトリ名
  repository = var.project_name
  # リポジトリドメイン
  domain = aws_codeartifact_domain.repo.domain
  # アップストリームリポジトリの指定
  # 設定しないと、CodeArtifactに作成したパッケージしか利用できなくなるため、設定推奨。
  # → 今回はNPM公式リポジトリのパッケージをキャッシュするようにする。
  upstream {
    repository_name = aws_codeartifact_repository.npm_public.repository
  }
  # 説明文
  description = var.project_name
  # タグ
  tags = {
    Name = var.project_name
  }
}

# アップストリームリポジトリの作成
# アップストリームリポジトリは設定しないと、
# CodeArtifactに作成したパッケージしか利用できなくなるため、設定推奨。
# → 今回はNPM公式リポジトリのパッケージをキャッシュするようにする。
resource "aws_codeartifact_repository" "npm_public" {
  # リポジトリ名
  repository = "npm-store"
  # リポジトリドメイン
  domain = aws_codeartifact_domain.repo.domain
  # 外部リポジトリ
  external_connections {
    external_connection_name = "public:npmjs"
  }
  # 説明文
  description = "Provides npm artifacts from npm, Inc."
  # タグ
  tags = {
    Name = var.project_name
  }
}

# リポジトリドメインの作成
resource "aws_codeartifact_domain" "repo" {
  # ドメイン名
  domain = var.project_name
  # 暗号化キー
  encryption_key = aws_kms_key.repo.arn
  # タグ
  tags = {
    Name = var.project_name
  }
}

# ドメインのためのKMSキーの作成
resource "aws_kms_key" "repo" {
  # 説明文
  description = var.project_name
  # キーの有効化
  is_enabled = true
  # KMSキーの削除待機期間(7-30日の範囲で指定する, default:30)
  deletion_window_in_days = 7
  # タグ
  tags = {
    Name = var.project_name
  }
}
