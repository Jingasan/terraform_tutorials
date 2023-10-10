#============================================================
# SES
#============================================================

# ホストゾーン情報の取得
data "aws_route53_zone" "main" {
  # ドメイン名
  name = var.route53_domain
  # パブリック証明書のリクエストを指定
  private_zone = false
}

# 検証済みIDの作成
resource "aws_ses_domain_identity" "domain" {
  # ドメイン名を設定
  domain = var.route53_domain
}

# SESのレコード追加
resource "aws_route53_record" "ses_record" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "_amazonses.${var.route53_domain}"
  type    = "TXT"
  ttl     = "600"
  records = [aws_ses_domain_identity.domain.verification_token]
}



#============================================================
# SES - メール送信元のなりすまし検出のための認証設定
# DKIM, DMARC, SPFの3手法を利用
#============================================================

# DKIMの設定
resource "aws_ses_domain_dkim" "dkim" {
  # 自ドメインに対してDKIMの設定を行う
  domain = aws_ses_domain_identity.domain.domain
}

# DKIMのレコード追加
resource "aws_route53_record" "dkim_record" {
  count   = 3
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "${element(aws_ses_domain_dkim.dkim.dkim_tokens, count.index)}._domainkey.${var.route53_domain}"
  type    = "CNAME"
  ttl     = "600"
  records = ["${element(aws_ses_domain_dkim.dkim.dkim_tokens, count.index)}.dkim.amazonses.com"]
}

# DMARC with DKIMのレコード追加
resource "aws_route53_record" "dmarc" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "_dmarc.${aws_ses_domain_identity.domain.domain}"
  type    = "TXT"
  ttl     = "60"
  records = ["v=DMARC1;p=none;rua=mailto:dmarc-reports@${aws_ses_domain_identity.domain.domain}"]
}

# DMARC with SPFのためのカスタムMAIL FROMドメインの作成
# SPFではMAIL FROMを利用して送信元の検証を行うため、カスタムのMAIL FROMを設定する。
# MAIL FROMドメインは検証済みドメインのサブドメインである必要がる。
resource "aws_ses_domain_mail_from" "this" {
  # 検証済みドメイン
  domain = aws_ses_domain_identity.domain.domain
  # 検証済みドメインのサブドメイン
  mail_from_domain = "bounce.${aws_ses_domain_identity.domain.domain}"
}

# MAIL FROMのレコード追加
resource "aws_route53_record" "mail_from_record" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = aws_ses_domain_mail_from.this.mail_from_domain
  type    = "MX"
  ttl     = "600"
  records = ["10 feedback-smtp.ap-northeast-1.amazonses.com"]
}

# カスタムMAIL FROMドメインに対するSPFのレコード追加
resource "aws_route53_record" "spf" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = aws_ses_domain_mail_from.this.mail_from_domain
  type    = "TXT"
  ttl     = "600"
  records = ["v=spf1 include:amazonses.com ~all"]
}

# FROMドメインに対するSPFのレコード追加
# docomoやauなどのキャリアは独自のなりすまし対策として
# MAIL FROMドメインとともにFROMドメインもチェックするため、
# FROMドメインに対してもSPFのTXTレコードを登録する。
resource "aws_route53_record" "spf_career" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = aws_ses_domain_identity.domain.domain
  type    = "TXT"
  ttl     = "600"
  records = ["v=spf1 include:amazonses.com ~all"]
}
