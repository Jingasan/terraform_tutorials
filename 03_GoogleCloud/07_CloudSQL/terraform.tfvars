#============================================================
# 環境変数の定義
#============================================================
# リージョン
region = "asia-northeast1"
#============================================================
# Compute Engine
#============================================================
# ゾーン
gce_zone = "asia-northeast1-b"
# OSイメージ
gce_image = "projects/debian-cloud/global/images/debian-11-bullseye-v20231115"
# マシンタイプ(インスタンスのvCPU数/メモリサイズの設定)
gce_machine_type = "custom-1-1024"
# ディスクサイズ(GB)(10-65536GBの範囲で指定)
gce_size = 10
# SSH接続を許可するユーザー
gce_allow_ssh_user = ["user:xxx@gmail.com"]
