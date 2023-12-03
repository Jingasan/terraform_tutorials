#============================================================
# Cloud DNS
#============================================================

# DNSレコードの追加
data "google_dns_managed_zone" "zone" {
  name = replace(var.certificate_manager_domain, ".", "-")
}
resource "google_dns_record_set" "default" {
  depends_on = [google_project_service.apis]
  # レコード追加先のDNSゾーン
  managed_zone = data.google_dns_managed_zone.zone.name
  # DNS名
  name = "${var.certificate_manager_domain}."
  # レコードタイプ
  type = "A"
  # 追加するレコードデータ
  rrdatas = [google_compute_global_address.default.address]
  # TTL(秒)
  ttl = 21600
}
