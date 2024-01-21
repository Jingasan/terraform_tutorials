#============================================================
# 環境変数の定義
#============================================================
# リージョン
region = "asia-northeast1"
#============================================================
# Certificate Manager
#============================================================
# ドメイン(事前にCloudDomainsで取得しておく)
certificate_manager_domain = "xxx.com"
#============================================================
# Compute Engine
#============================================================
# ゾーン
gce_zone = "asia-northeast1-a"
# OSイメージ
gce_image = "projects/debian-cloud/global/images/debian-12-bookworm-v20240110"
# マシンタイプ(インスタンスのvCPU数/メモリサイズの設定)
gce_machine_type = "e2-medium"
# ブートディスクの種類
# pd-balanced：バランス永続ディスク
# pd-extremeエクストリーム永続ディスク
# pd-ssd：SSD永続ディスク
# pd-standard：標準永続ディスク
gce_type = "pd-balanced"
# ディスクサイズ(GB)(10-65536GBの範囲で指定)
gce_size = 10
# VMプロビジョニングモデル(STANDARD/SPOT)
gce_provisioning_model = "STANDARD"
# ネットワークサービスのプラン
# STANDARD:単一リージョン内で閉じたサービス向け, PREMIUMよりも安価
# PREMIUM(default):グローバルな可用性を必要とするサービス向け
# https://cloud.google.com/network-tiers/docs/overview
gce_network_tier = "PREMIUM"
# SSH接続を許可するユーザー
gce_allow_ssh_user = ["user:xxx@gmail.com"]
