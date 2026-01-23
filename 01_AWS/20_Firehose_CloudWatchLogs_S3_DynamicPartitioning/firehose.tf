#============================================================
# Data Firehose
#============================================================

# Data Firehoseのストリーム設定
resource "aws_kinesis_firehose_delivery_stream" "lambda_cloudwatch_log_to_s3" {
  # ストリーム名
  name = "${var.project_name}-lambda-cloudwatch-log-to-s3"
  # データの転送先のAWSサービス（extended_s3／redshift／elasticsearch／splunk／http_endpoint／opensearch／opensearchserverless／snowflake）
  destination = "extended_s3"
  # S3転送の詳細設定
  extended_s3_configuration {
    # 転送先S3バケットのARN
    bucket_arn = aws_s3_bucket.bucket_lambda_cloudwatch_log.arn
    # データをS3に転送するためのIAMロールのARN
    role_arn = aws_iam_role.firehose_role.arn
    # 動的パーティション分割の有効化（true:有効）
    # 有効化することで、S3オブジェクトのプレフィックスにデータ内のキー（例：customer_id, transaction_id, log_groupなど）を自動付与できる。
    dynamic_partitioning_configuration {
      enabled = "true"
    }
    # S3オブジェクトのプレフィックス設定
    prefix = "logs/log_group=!{partitionKeyFromQuery:logGroup}/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/hour=!{timestamp:HH}/"
    # S3オブジェクトのエラープレフィックス設定
    error_output_prefix = "errors/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/hour=!{timestamp:HH}/!{firehose:error-output-type}/"
    # 圧縮フォーマットの設定（UNCOMPRESSED（default）／GZIP／ZIP／Snappy／HADOOP_SNAPPY）
    compression_format = "GZIP"
    # タイムゾーンの設定（default:UTC）
    custom_time_zone = "Asia/Tokyo"
    # バッファリングサイズ（MB）の設定
    #   動的パーティション分割無効時：（default: 5, 最小: 1, 最大: 128）
    #   動的パーティション分割有効時：（default: 64, 最小: 64, 最大: 128）
    # データを転送する際に指定されたサイズまでバッファリングしてから転送する。
    # バッファサイズが大きいほど、コストが低くなり、レイテンシーが高くなる可能性がある。
    # バッファサイズが小さいほど、配信が高速になり、コストが高くなり、レイテンシーが低くなる。
    buffering_size = var.firehose_buffering_size_mb
    # バッファリング間隔（秒）の設定
    #   動的パーティション分割無効時：（default: 300, 最小: 60, 最大: 900）
    #   動的パーティション分割有効時：（default: 300, 最小: 0, 最大: 900）
    # データを転送する際に指定された秒数までバッファリングしてから転送する。
    # 間隔が長いほど、データを収集する時間が長くなり、データのサイズが大きくなる場合がある。
    # 間隔が短いほど、データが送信される頻度が高くなり、より短期サイクルでデータアクティビティを確認する場合のメリットが多くなる場合がある。
    buffering_interval = var.firehose_buffering_interval_sec
    # 転送されてきたレコードに対する処理の設定
    processing_configuration {
      # レコード処理の有効化（true:有効）
      enabled = true
      # レコードプロセッサの設定１
      processors {
        # レコードプロセッサの種類の設定
        # Decompression：CloudWatchLogsのレコード(GZIP形式)を一旦解凍するプロセッサ。（※要追加料金）
        # MetadataExtraction：CloudWatchLogsのレコードからメタデータ抽出できるプロセッサ。Decompressionプロセッサが必須。
        # AppendDelimiterToRecord：レコードの末尾にデリミタを追加するプロセッサ。（Athenaを利用する場合、デリミタを入れないと改行区切りのない1行のJSONでS3に保存され、解析が難しくなるため必要）
        # CloudWatchLogProcessing：CloudWatchLogsレコードを処理するプロセッサ。メッセージフィールドのみを抜き出すなどの処理が可能。Decompressionプロセッサが必須。
        type = "Decompression"
        # レコードプロセッサのパラメータ設定
        parameters {
          # パラメータ名と値の設定
          parameter_name  = "CompressionFormat"
          parameter_value = "GZIP"
        }
      }
      # レコードプロセッサの設定２
      processors {
        # レコードプロセッサの種類の設定
        # Decompression：CloudWatchLogsのレコード(GZIP形式)を一旦解凍するプロセッサ。（※要追加料金）
        # MetadataExtraction：CloudWatchLogsのレコードからメタデータ抽出できるプロセッサ。Decompressionプロセッサが必須。
        # AppendDelimiterToRecord：レコードの末尾にデリミタを追加するプロセッサ。（Athenaを利用する場合、デリミタを入れないと改行区切りのない1行のJSONでS3に保存され、解析が難しくなるため必要）
        # CloudWatchLogProcessing：CloudWatchLogsレコードを処理するプロセッサ。メッセージフィールドのみを抜き出すなどの処理が可能。Decompressionプロセッサが必須。
        type = "MetadataExtraction"
        # レコードプロセッサのパラメータ設定
        parameters {
          # 転送データのJSONパースエンジン設定
          parameter_name  = "JsonParsingEngine"
          parameter_value = "JQ-1.6"
        }
        # レコードプロセッサのパラメータ設定
        parameters {
          # CloudWatch Logsから渡る転送データ（JSON形式）のメタデータ抽出クエリ設定
          parameter_name  = "MetadataExtractionQuery"
          parameter_value = "{logGroup:.logGroup}" # 転送されてきたJSONのlogGroupキーの値を抽出
        }
      }
      # レコードプロセッサの設定３
      processors {
        # レコードプロセッサの種類の設定
        # Decompression：CloudWatchLogsのレコード(GZIP形式)を一旦解凍するプロセッサ。（※要追加料金）
        # MetadataExtraction：CloudWatchLogsのレコードからメタデータ抽出できるプロセッサ。Decompressionプロセッサが必須。
        # AppendDelimiterToRecord：レコードの末尾にデリミタを追加するプロセッサ。（Athenaを利用する場合、デリミタを入れないと改行区切りのない1行のJSONでS3に保存され、解析が難しくなるため必要）
        # CloudWatchLogProcessing：CloudWatchLogsレコードを処理するプロセッサ。メッセージフィールドのみを抜き出すなどの処理が可能。Decompressionプロセッサが必須。
        type = "AppendDelimiterToRecord"
      }
    }
    # CloudWatch Logsへのログ出力設定（データ転送に失敗した場合にエラーログを出力する）
    cloudwatch_logging_options {
      # CloudWatch Logsへのログ出力の有効化（true:有効）
      enabled = true
      # ロググループ名
      log_group_name = aws_cloudwatch_log_group.firehose_lambda_cloudwatch_log_to_s3.name
      # CloudWatch Logsのログストリーム名
      log_stream_name = aws_cloudwatch_log_stream.firehose_lambda_cloudwatch_log_to_s3.name
    }
  }
  # タグ
  tags = {
    Name = var.project_name
  }
}



#============================================================
# CloudWatch Logs
#============================================================

# DataFirehoseでデータ転送に失敗した場合にエラーログを出力するCloudWatchロググループの設定
resource "aws_cloudwatch_log_group" "firehose_lambda_cloudwatch_log_to_s3" {
  # CloudWatchロググループ名
  name = "/aws/kinesisfirehose/${var.project_name}-lambda-cloudwatch-log-to-s3"
  # ログを残す期間(日)の指定
  retention_in_days = var.lambda_cloudwatch_log_retention_in_days
  # タグ
  tags = {
    Name = var.project_name
  }
}

# DataFirehoseでデータ転送に失敗した場合にエラーログを出力するCloudWatchログストリームの設定
resource "aws_cloudwatch_log_stream" "firehose_lambda_cloudwatch_log_to_s3" {
  # ログストリーム名
  name = "${var.project_name}-lambda-cloudwatch-log-to-s3"
  # 作成先のロググループ名
  log_group_name = aws_cloudwatch_log_group.firehose_lambda_cloudwatch_log_to_s3.name
}
