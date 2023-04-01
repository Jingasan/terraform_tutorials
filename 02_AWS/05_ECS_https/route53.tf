#==============================
# Route53
#==============================

# ホストゾーンの定義
data "aws_route53_zone" "main" {
  # 作成済みのホストゾーン(取得済みのドメイン)の指定
  name = "api-server-tutorial.com"
  # パブリック証明書のリクエストを指定
  private_zone = false
}

# ALBのDNS名と上記の取得済みドメイン名を紐付けるDNSレコードをホストゾーンに作成
resource "aws_route53_record" "example" {
  # DNSレコードを挿入するホストゾーンを指定
  zone_id = data.aws_route53_zone.main.zone_id
  name    = data.aws_route53_zone.main.name
  # ALIASレコードを挿入：ALBのDNS名と上記の取得済みドメイン名を紐付け
  type = "A"
  alias {
    name                   = aws_lb.example.dns_name
    zone_id                = aws_lb.example.zone_id
    evaluate_target_health = true
  }
}

# ACMによる証明書の作成
resource "aws_acm_certificate" "cert" {
  # 証明書発行対象のドメイン名
  domain_name = "api-server-tutorial.com"
  # サブドメインに対しても証明書を有効化
  subject_alternative_names = ["*.api-server-tutorial.com"]
  # ドメインの認証方法の指定：DNS認証
  validation_method = "DNS"
  # 既存の証明書があった場合に一旦削除してから作り直す設定
  lifecycle {
    create_before_destroy = true
  }
  # タグ
  tags = {
    "Name" = "Terraform検証用"
  }
}

# ACMで作成したSSL/TLS証明書のDNS検証のためのDNSレコードをホストゾーンに作成
resource "aws_route53_record" "cert_validation" {
  # DNSレコードを挿入するホストゾーンを指定
  zone_id = data.aws_route53_zone.main.zone_id
  # ACM DNS検証用のDNSレコードを挿入
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }
  name            = each.value.name
  type            = each.value.type
  records         = [each.value.record]
  ttl             = 60
  allow_overwrite = true
}

# ACMで作成したSSL/TLS証明書のDNS検証実施
resource "aws_acm_certificate_validation" "cert" {
  # 作成した証明書の指定
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

# ドメイン名の出力
output "domain_name" {
  value = data.aws_route53_zone.main.name
}
