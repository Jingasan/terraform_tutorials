#============================================================
# Route53
#============================================================

# 作成済みのホストゾーンの取得
data "aws_route53_zone" "main" {
  # 作成済みのホストゾーン名（＝ドメイン名）の指定
  name = var.route53_domain
  # プライベートホストゾーンかどうか（true:プライベートホストゾーン／false:パブリックホストゾーン）
  private_zone = false
}



#============================================================
# SES
#============================================================

# ドメインタイプのID作成
# IDとは、SESにおいて、メール送信元となるメールアドレスまたはドメインのことである。
# SESからメールを送信する場合は、SESにIDを登録する。
resource "aws_ses_domain_identity" "domain" {
  # ドメイン名の指定
  domain = var.route53_domain
}

# 送信元メールアドレスの認証の為、SESで使うドメインのDNSレコード追加
# 尚、この時点でSPFとDKIM（ドメインはamazonses.com）の認証に合格するが、自ドメインに対するDKIMの認証には失敗する。
resource "aws_route53_record" "ses_record" {
  # レコード追加先のホストゾーンのID
  zone_id = data.aws_route53_zone.main.zone_id
  # レコード名
  name = "_amazonses.${var.route53_domain}"
  # レコードタイプ
  type = "TXT"
  # TTL
  ttl = "600"
  # SESで使うドメインのレコードをDNSに追加
  # 個別で送信元メールアドレスを認証することもできるが、ドメインレベルで認証することで、
  # そのドメインを持つすべてのメールアドレスからメール送信が可能になる。
  records = [aws_ses_domain_identity.domain.verification_token]
}



#============================================================
# SESにおける、メール送信元なりすまし対策およびメール内容改竄対策の為のドメイン認証の設定
# SPF, DKIM, DMARCを利用する。
# SPF（Sender Policy Framework）
#   電子メールの送信者を認証するための方法。
#   SPFの仕組みでは、ドメインのDNSレコードの中に、そのドメインからのメール送信を許可するメール送信サーバーのリストを含める。
#   これを元に、受信サーバーがメールの送信元が正当であるかを確認する。
# DKIM（Domain Keys Identified Mail）
#   電子メールの内容が送信途中で改竄されていないことを保証するための方法。
#   DKIMの仕組みでは、メール送信サーバーはメールにデジタル署名を追加し、受信サーバーはその署名を検証することで、メールの真正性を確認する。
# DMARC（Domain-based Message Authentication; Reporting, and Conformance）
#   SPFとDKIMの結果を活用し、メールが正当な送信元から送信されているかを確認し、レポートとして収集するプロトコル。
#   DMARCを利用するには、SPFかDKIMの少なくとも一方が割り当てられている必要がある。
#   DMARCの仕組みでは、メールがSPFまたはDKIMをパスした場合、そのメールの「FROM」ドメインがSPFの「Return-Path」ドメインやDKIMの署名ドメインとどの程度一致しているか（アライメント）を確認する。
#   一致しないメールに対し、設定したDMARCポリシーに基づき、メールを受け入れるか、拒否するか、隔離するか（迷惑メールとして扱うか）を決定する。
# アライメント
#   DMARCにおいて、メールの「From」ドメインがSPFまたはDKIMの認証結果とどの程度一致しているかを示す用語。
# SPFアライメント
#   SPFにおいて、メールの「Return-Path」（または「Mail-From」）ドメインが「From」ヘッダーのドメインと一致しているかどうかを確認する処理。
#   Strictモード：メールの「Return-Path」ドメインと「From」ドメインが完全に一致している必要がある。
#   Relaxedモード：トップレベルドメイン（TLD）とサブドメインが一致していれば、完全な一致ではなくても受け入れる。
# DKIMアライメント
#   DKIMにおいて、メールのDKIM署名ヘッダー内の「d=」フィールド（署名ドメイン）が「From」ヘッダーのドメインと一致しているかどうかを確認する処理。
#   Strictモード：DKIM署名の「d=」ドメインと「From」ドメインが完全に一致している必要がある。
#   Relaxedモード：トップレベルドメインとサブドメインが一致していれば、完全一致ではなくても受け入れる。
#============================================================

# 自ドメインに対するDKIM（Easy DKIM）の設定
resource "aws_ses_domain_dkim" "this" {
  # 自ドメインに対してDKIMの設定を行う
  domain = aws_ses_domain_identity.domain.domain
}

# DKIM用のDNSレコード追加
resource "aws_route53_record" "dkim_record" {
  count = 3
  # レコード追加先のホストゾーンのID
  zone_id = data.aws_route53_zone.main.zone_id
  # レコード名
  name = "${element(aws_ses_domain_dkim.this.dkim_tokens, count.index)}._domainkey.${var.route53_domain}"
  # レコードタイプ
  type = "CNAME"
  # TTL
  ttl = "600"
  # DKIM用のレコードをDNSに追加
  records = ["${element(aws_ses_domain_dkim.this.dkim_tokens, count.index)}.dkim.amazonses.com"]
}

# DKIMまたはSPFによるDMARC準拠の為のDNSレコード追加
resource "aws_route53_record" "dmarc" {
  # レコード追加先のホストゾーンのID
  zone_id = data.aws_route53_zone.main.zone_id
  # レコード名
  name = "_dmarc.${aws_ses_domain_identity.domain.domain}"
  # レコードタイプ
  type = "TXT"
  # TTL
  ttl = "60"
  # DKIMまたはSPFに合格しなかったメールをどのように処理するかの設定
  # v：DMARCのバージョン設定。常にDMARC1。
  # p：ポリシー設定（=メールの扱い方）。
  #    reject：DMARCチェック（＝SPFまたはDKIM）に失敗したメールを「完全に拒否」する。（DMARCが完全に整った段階で利用）
  #    quarantine：DMARCチェック（＝SPFまたはDKIM）に失敗したメールを「隔離（迷惑メール扱い）」にする。（実運用初期で利用）
  #    none：DMARCチェックを行い、結果をレポートとして送信元ドメインに送るが、メール送信には何も関与しない。（検証・テスト段階で利用）
  # pct：適用割合。100を指定すると、100%のメールにこのポリシーを適用する。
  # rua：集計レポート送信先の設定。送信元サーバー（ここではSES）が送信結果の統計をこのアドレスに送信してくれる。（省略可）
  # ruf：詳細レポート送信先の設定。DMARC失敗時の詳細レポート（実際のメールヘッダーなど）を送信してくれる。（省略可）
  records = ["v=DMARC1;p=quarantine;pct=100;rua=mailto:dmarc-reports@${aws_ses_domain_identity.domain.domain}"]
}

# SPFによるDMARC準拠の為のMAIL FROMドメインの作成
# SPFでは、MAIL FROMを利用して送信元の検証を行う為、SPF用にMAIL FROMドメインを追加する。
# MAIL FROMのドメインには、検証済みのドメインのサブドメイン（例：bounce.ドメイン名）を指定する必要がある。
# ※ ただし、すでに上記でDKIMによるDMARC準拠を行っている為、SPFによるDMARC準拠は必須ではない。
resource "aws_ses_domain_mail_from" "this" {
  # 検証済みドメインの指定
  domain = aws_ses_domain_identity.domain.domain
  # 検証済みドメインのサブドメインの指定
  mail_from_domain = "bounce.${aws_ses_domain_identity.domain.domain}"
}

# SPFによるDMARC準拠の為のMAIL FROMドメインのDNSレコード追加
# ※ ただし、すでに上記でDKIMによるDMARC準拠を行っている為、SPFによるDMARC準拠は必須ではない。
resource "aws_route53_record" "mail_from_mx" {
  # レコード追加先のホストゾーンのID
  zone_id = data.aws_route53_zone.main.zone_id
  # レコード名
  name = aws_ses_domain_mail_from.this.mail_from_domain
  # レコードタイプ
  type = "MX"
  # TTL
  ttl = "600"
  # AWSが提供するバウンス（送信失敗などの通知）受信用メールサーバー「feedback-smtp.ap-northeast-1.amazonses.com」の場所を優先度10でレコードとして追加
  records = ["10 feedback-smtp.ap-northeast-1.amazonses.com"]
}

# SPFによるDMARC準拠の為の、MAIL FROMドメインのDNSレコード追加
# ※ ただし、すでに上記でDKIMによるDMARC準拠を行っている為、SPFによるDMARC準拠は必須ではない。
resource "aws_route53_record" "spf" {
  # レコード追加先のホストゾーンのID
  zone_id = data.aws_route53_zone.main.zone_id
  # レコード名
  name = aws_ses_domain_mail_from.this.mail_from_domain
  # レコードタイプ
  type = "TXT"
  # TTL
  ttl = "600"
  # 実際に送信元メールサーバーのIPアドレス情報はamazonses.comのゾーンにある為、
  # includeを用い、include先ドメインのSPFレコードで認証処理が通る場合に認証を通すDNSレコードを追加
  # ※ amazonses.comのDNSレコードは事前に追加済み
  records = ["v=spf1 include:amazonses.com ~all"]
}

# SPFによるDMARC準拠の為の、HEADER FROMドメインのDNSレコード追加
# docomoやauなどのキャリアは独自のなりすまし対策として、
# MAIL FROMドメインとともにFROMドメインもチェックするため、HEADER FROMドメインのDNSレコードも登録する。
# ※ ただし、すでに上記でDKIMによるDMARC準拠を行っている為、SPFによるDMARC準拠は必須ではない。
resource "aws_route53_record" "spf_career" {
  # レコード追加先のホストゾーンのID
  zone_id = data.aws_route53_zone.main.zone_id
  # レコード名
  name = aws_ses_domain_identity.domain.domain
  # レコードタイプ
  type = "TXT"
  # TTL
  ttl = "600"
  # 実際に送信元メールサーバーのIPアドレス情報はamazonses.comのゾーンにある為、
  # includeを用い、include先ドメインのSPFレコードで認証処理が通る場合に認証を通すDNSレコードを追加
  # ※ amazonses.comのDNSレコードは事前に追加済み
  records = ["v=spf1 include:amazonses.com ~all"]
}
