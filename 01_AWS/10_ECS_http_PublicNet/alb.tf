#==============================
# ALB
#==============================

# ALBの作成
resource "aws_lb" "example" {
  # ALBの名前
  name = "example-terraform-alb"
  # ロードバランサ―の種類（ALB: application, NLB: network）
  load_balancer_type = "application"
  # インターネット向けなのかVPC内部向けなのか
  internal = false # false: インターネット向け
  # タイムアウト時間(default: 60s, 最大: 4000s)
  idle_timeout = 4000
  # 削除保護(true:有効)(本番環境では誤って削除しないようにtrueにする)
  enable_deletion_protection = false
  # ALBを所属させるサブネット
  subnets = [
    aws_subnet.public_a.id,
    aws_subnet.public_c.id,
  ]
  # アクセスログ保存先のS3バケットの指定
  access_logs {
    bucket  = aws_s3_bucket.alb_log.id
    prefix  = "example-terraform-alb"
    enabled = true
  }
  # セキュリティグループの指定
  security_groups = [
    module.http_sg.security_group_id,
  ]
  # タグ
  tags = {
    "Name" = "Terraform検証用"
  }
}

# リスナーの作成
resource "aws_lb_listener" "http" {
  # ALB IDの指定
  load_balancer_arn = aws_lb.example.arn
  # HTTPでのアクセスを受け付ける
  port     = "80"
  protocol = "HTTP"
  # デフォルトアクション
  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      status_code  = "200"
      message_body = "This is HTTP."
    }
  }
  # タグ
  tags = {
    "Name" = "Terraform検証用"
  }
}

# リスナールール
resource "aws_lb_listener_rule" "ecs" {
  # HTTPのリスナーにリスナールールを追加
  listener_arn = aws_lb_listener.http.arn
  # リスナールールの実行優先順位
  priority = 100
  # 作成したターゲットグループにアクセスを転送する
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ecs.arn
  }
  # アクセスを転送するURLのパスルール
  condition {
    path_pattern {
      values = ["/*"]
    }
  }
}

# ALBターゲットグループの作成
resource "aws_lb_target_group" "ecs" {
  # ターゲットグループ名
  name = "example-terraform-target-group"
  # ターゲットの種類の指定
  target_type = "ip" # Fargateの場合はipを指定する
  # 関連するVPCのIDの指定
  vpc_id = aws_vpc.example.id
  # プロトコルとポート番号の指定
  port     = 80
  protocol = "HTTP"
  # 登録解除前にALBが待機する時間[s]
  deregistration_delay = 300
  # ヘルスチェックの設定
  health_check {
    path                = "/"            # ヘルスチェックで使用するパス
    healthy_threshold   = 5              # 正常判定を行うまでのヘルスチェック実行回数
    unhealthy_threshold = 2              # 異常判定を行うまでのヘルスチェック実行回数
    timeout             = 5              # ヘルスチェックのタイムアウト時間[s]
    interval            = 30             # ヘルスチェックの実行間隔[s]
    matcher             = 200            # 正常判定を行うために使用するHTTPステータスコード
    protocol            = "HTTP"         # ヘルスチェック時に使用するプロトコル
    port                = "traffic-port" # ヘルスチェックで使用するポート番号
    # traffic-portを指定すると上記で指定したポートと同じポート番号を使用する
  }
  # 依存関係
  depends_on = [aws_lb.example] # ターゲットグループをECSサービスと同時に作成するとエラーとなるため追加
}

# DNSネームの出力
output "alb_dns_name" {
  value = aws_lb.example.dns_name
}


#==============================
# セキュリティグループ
#==============================

# セキュリティグループの作成(HTTP 80番ポートの許可)
module "http_sg" {
  # 利用するモジュールの指定
  source = "./security_group"
  # セキュリティグループ名の指定
  name = "http-sg"
  # セキュリティグループを割り当てるVPC IDの指定
  vpc_id = aws_vpc.example.id
  # 通信を許可するポート番号/IPの指定
  port        = 80
  cidr_blocks = ["0.0.0.0/0"]
}
