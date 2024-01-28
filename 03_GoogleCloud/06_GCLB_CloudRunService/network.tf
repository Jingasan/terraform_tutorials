#============================================================
# Network
#============================================================

# 外部静的IPアドレスの予約
# 外部静的IPアドレスは外部HTTP(S)ロードバランサーに設定する。
# また、Cloud DNSにドメインと登録し、ドメインと対応付ける。
resource "google_compute_global_address" "default" {
  depends_on = [google_project_service.apis]
  # 外部静的IPアドレスの名前
  name = var.project_id
  # IPバージョン(IPV4(default)/IPV6)
  ip_version = "IPV4"
  # タイプ(INTERNAL:リージョン内部ネットワークIPアドレスの範囲/EXTERNAL(default):単一のグローバルIPアドレス)
  address_type = "EXTERNAL"
  # 説明文
  description = var.project_id
}

# 外部静的IPアドレスの表示
output "ip_address" {
  description = "ip_address"
  value       = google_compute_global_address.default.address
}
