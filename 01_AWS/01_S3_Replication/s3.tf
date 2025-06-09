#============================================================
# S3（レプリケーション元のバケット）
#============================================================

# レプリケーション元バケットの作成
resource "aws_s3_bucket" "bucket" {
  # バケット名
  bucket = "${var.project_name}-${local.lower_random_hex}"
  # バケットの中にオブジェクトが入っていてもTerraformに削除を許可するかどうか（true:許可）
  force_destroy = true
  # タグ
  tags = {
    Name = var.project_name
  }
}

# オブジェクトのバージョン管理の設定
resource "aws_s3_bucket_versioning" "bucket" {
  # バージョン管理を設定するバケットのID
  bucket = aws_s3_bucket.bucket.id
  # バージョン管理の設定
  versioning_configuration {
    status = "Enabled"
  }
}

# S3バケットオブジェクトのライフサイクルルール（オブジェクトが永遠にバージョニングされない為に必須）
resource "aws_s3_bucket_lifecycle_configuration" "bucket" {
  # 対象となるバケットのID
  bucket = aws_s3_bucket.bucket.id
  # ライフサイクルルールの設定
  rule {
    # ルール名
    id = "${var.project_name}-bucket-${local.lower_random_hex}"
    # ルールのステータス（Enabled:有効）
    status = "Enabled"
    # ルール適用対象のオブジェクトをprefixで指定
    filter {
      prefix = "" # すべてのオブジェクトに適用
    }
    # 移行ルール（INTELLIGENT_TIERINGクラスで保管する）
    transition {
      # 移行先のストレージクラス
      storage_class = "INTELLIGENT_TIERING"
      # 移行スケジュール
      days = 0 # オブジェクトが格納されて24h以内に移行
    }
    # オブジェクトの非最新バージョンの削除設定
    noncurrent_version_expiration {
      # 非最新バージョンの保持日数（日）：1以上の値を指定。指定日数が経過したら非最新バージョンを削除される。
      noncurrent_days = var.s3_lifecycle_noncurrent_version_expiration_days
      # 保持するバージョン数（個）
      newer_noncurrent_versions = var.s3_lifecycle_newer_noncurrent_versions
    }
  }
}



#============================================================
# S3（レプリケーション先のバケット）
#============================================================

# レプリケーション先バケットの作成
resource "aws_s3_bucket" "bucket_replication" {
  # バックアップ先のリージョンを指定
  provider = aws.s3_replication_region
  # S3バケット名
  bucket = "${var.project_name}-backup-replication-${local.lower_random_hex}"
  # バケットの中にオブジェクトが入っていてもTerraformに削除を許可するかどうか（true:許可）
  force_destroy = true
  # タグ
  tags = {
    Name = var.project_name
  }
}

# オブジェクトのバージョン管理の設定
resource "aws_s3_bucket_versioning" "bucket_replication" {
  # バックアップ先のリージョンを指定
  provider = aws.s3_replication_region
  # バージョン管理を設定するバケットのID
  bucket = aws_s3_bucket.bucket_replication.id
  # バージョン管理の設定
  versioning_configuration {
    # バージョン管理のステータス（Enabled:有効）
    status = "Enabled"
  }
}

# S3バケットオブジェクトのライフサイクルルール（オブジェクトが永遠にバージョニングされない為に必須）
resource "aws_s3_bucket_lifecycle_configuration" "bucket_replication" {
  # バックアップ先のリージョンを指定
  provider = aws.s3_replication_region
  # 対象となるバケットのID
  bucket = aws_s3_bucket.bucket_replication.id
  # ライフサイクルルールの設定
  rule {
    # ルール名
    id = "${var.project_name}-backup-replication-${local.lower_random_hex}"
    # ルールのステータス（Enabled:有効）
    status = "Enabled"
    # ルール適用対象のオブジェクトをprefixで指定
    filter {
      prefix = "" # すべてのオブジェクトに適用
    }
    # 移行ルール（DEEP_ARCHIVEクラスで保管する）
    transition {
      # 移行先のストレージクラス
      storage_class = "DEEP_ARCHIVE"
      # 移行スケジュール
      days = 0 # オブジェクトが格納されて24h以内に移行
    }
    # オブジェクトの非最新バージョンの削除設定
    noncurrent_version_expiration {
      # 非最新バージョンの保持日数（日）：1以上の値を指定。指定日数が経過したら非最新バージョンを削除される。
      noncurrent_days = var.s3_lifecycle_noncurrent_version_expiration_days
      # 保持するバージョン数（個）
      newer_noncurrent_versions = var.s3_lifecycle_newer_noncurrent_versions
    }
  }
}

# レプリケーション設定
resource "aws_s3_bucket_replication_configuration" "bucket_replication" {
  depends_on = [aws_s3_bucket_versioning.bucket]
  # レプリケーション元のバケットID
  bucket = aws_s3_bucket.bucket.id
  # バケット間のレプリケーションを許可するIAMロールのARN
  role = aws_iam_role.bucket_replication_role.arn
  # レプリケーションのルール
  rule {
    # ルールID
    id = "${var.project_name}-bucket-replication-configuration-role-${local.lower_random_hex}"
    # ルールのステータス（Enabled:有効）
    status = "Enabled"
    # レプリケーション対象のフィルタリング
    filter {
      prefix = "" # 全オブジェクトを対象
    }
    # レプリケーション先の設定
    destination {
      # レプリケーション先のバケットのARN
      bucket = aws_s3_bucket.bucket_replication.arn
      # レプリケーション時のストレージクラス
      storage_class = "DEEP_ARCHIVE"
    }
    # 削除マーカーのレプリケーション設定
    delete_marker_replication {
      # 削除もレプリケートするか（Enabled:レプリケートする）
      status = "Enabled"
    }
  }
}



#============================================================
# IAMロール（S3）
#============================================================

# データ用バケットのレプリケーション用のIAMロール
resource "aws_iam_role" "bucket_replication_role" {
  # IAMロール名
  name = "${var.project_name}-iam-role-bucket-replication-role-${local.lower_random_hex}"
  # IAMロール
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "s3.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
  # 説明
  description = "${var.project_name}-iam-role-bucket-replication-role-${local.lower_random_hex}"
  # タグ
  tags = {
    Name = "${var.project_name}-iam-role-bucket-replication-role-${local.lower_random_hex}"
  }
}

# IAMロールに対するポリシーの設定
resource "aws_iam_role_policy" "bucket_replication_policy" {
  # ポリシー名
  name = "${var.project_name}-iam-role-policy-bucket-replication-role-${local.lower_random_hex}"
  # 割り当て先のIAMロール
  role = aws_iam_role.bucket_replication_role.id
  # IAMロールポリシー
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:GetReplicationConfiguration",
          "s3:ListBucket",
          "s3:GetObjectVersion",
          "s3:GetObjectVersionAcl",
          "s3:GetObjectVersionTagging",
          "s3:GetObjectRetention",
          "s3:GetObjectLegalHold",
          "s3:ReplicateObject",
          "s3:ReplicateDelete",
          "s3:ReplicateTags",
          "s3:ObjectOwnerOverrideToBucketOwner"
        ],
        Resource = [
          "${aws_s3_bucket.bucket.arn}",
          "${aws_s3_bucket.bucket.arn}/*",
          "${aws_s3_bucket.bucket_replication.arn}",
          "${aws_s3_bucket.bucket_replication.arn}/*",
        ]
      },
    ]
  })
}
