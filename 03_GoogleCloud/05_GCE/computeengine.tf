#============================================================
# Compute Engine
#============================================================

# VMインスタンスの作成
resource "google_compute_instance" "instance" {
  depends_on = [google_project_service.apis]
  # VMインスタンス名
  name = var.project_id
  # ゾーン
  zone = var.gce_zone
  # マシンタイプ(インスタンスのvCPU数/メモリサイズの設定)
  machine_type = var.gce_machine_type
  # Confidential VMs サービスの有効化(true:有効)
  confidential_instance_config {
    enable_confidential_compute = false
  }
  # ブートディスクの設定
  boot_disk {
    # 名前(VMインスタンス名と同一にすること)
    device_name = var.project_id
    # OSイメージの設定
    initialize_params {
      # OSイメージ
      image = var.gce_image
      # ブートディスクの種類
      # pd-balanced：バランス永続ディスク
      # pd-extremeエクストリーム永続ディスク
      # pd-ssd：SSD永続ディスク
      # pd-standard：標準永続ディスク
      type = var.gce_type
      # ディスクサイズ(GB)(10-65536GBの範囲で指定)
      size = var.gce_size
    }
    # ディスクのモード(READ_ONLY:読み込み専用/READ_WRITE:読み書き用)
    mode = "READ_WRITE"
    # VMインスタンス削除時のディスク自動削除設定(true:自動削除(default))
    auto_delete = true
  }
  # プロビジョニング設定
  scheduling {
    # VMプロビジョニングモデル(STANDARD/SPOT)
    provisioning_model = var.gce_provisioning_model
    # 自動再起動の有効化(true:有効(default)/false:無効)
    automatic_restart = true
  }
  # 画面キャプチャツールと録画ツールの有効化(true:有効/false:無効(default))
  enable_display = false
  # サービスアカウントの設定
  service_account {
    email  = google_service_account.gce.email
    scopes = ["cloud-platform"]
  }
  # ファイアウォール設定
  tags = [
    "ssh-server",     # ファイアウォール設定でSSHを許可するためのタグ
    "http-server",    # HTTPトラフィックを許可する
    "https-server",   # HTTPSトラフィックを許可する
    "lb-health-check" # ロードバランサのヘルスチェックを許可する
  ]
  # IP転送設定(true:VMインスタンスがパケットをルーティングする/false(default))
  can_ip_forward = false
  # ネットワークインターフェースの設定
  network_interface {
    # ネットワーク
    access_config {
      # ネットワークサービスのプラン
      # STANDARD:単一リージョン内で閉じたサービス向け, PREMIUMよりも安価
      # PREMIUM(default):グローバルな可用性を必要とするサービス向け
      # https://cloud.google.com/network-tiers/docs/overview
      network_tier = var.gce_network_tier
    }
    # VPCネットワーク
    network = google_compute_network.vpc.id
    # サブネットワーク
    subnetwork = google_compute_subnetwork.subnet.id
  }
  # セキュリティ設定
  shielded_instance_config {
    # セキュアブートの有効化(true:有効/false:無効(fefault))
    enable_secure_boot = false
    # vTPMの有効化(true:有効(default)/false:無効)
    enable_vtpm = true
    # 整合性モニタリングの有効化(true:有効(default)/false:無効)
    enable_integrity_monitoring = true
  }
  # インスタンス起動時に実行するスクリプト
  metadata_startup_script = <<EOF
    #!/bin/bash
    apt-get update
    apt-get -y install apache2
    systemctl restart apache2
    EOF
  # VMインスタンスの削除禁止(true:削除を禁止する/false:削除を許可する)
  deletion_protection = false
  # VMインスタンスの説明
  description = var.project_id
  # タグ
  labels = {
    name = var.project_id
  }
}

# ComputeEngine用のサービスアカウントの作成
resource "google_service_account" "gce" {
  depends_on = [google_project_service.apis]
  # サービスアカウントID
  account_id = var.project_id
  # 表示名
  display_name = var.project_id
  # 説明文
  description = var.project_id
}

# VPCネットワークの作成
resource "google_compute_network" "vpc" {
  depends_on = [google_project_service.apis]
  # VPCネットワーク名
  name = var.project_id
  # サブネットの自動生成(true:自動生成/false)
  auto_create_subnetworks = false
  # MTU
  mtu = 1460
}

# サブネットの作成
resource "google_compute_subnetwork" "subnet" {
  depends_on = [google_project_service.apis]
  # サブネット名
  name = var.project_id
  # リージョン
  region = var.region
  # サブネットで使用する内部IPアドレスの範囲
  network       = google_compute_network.vpc.id
  ip_cidr_range = "10.0.1.0/24"
  # CloudLogggingにFlowLogを出力する設定
  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

# ファイアウォール設定の作成
resource "google_compute_firewall" "gce" {
  depends_on = [google_project_service.apis]
  # ファイアウォール設定名
  name = var.project_id
  # ファイアウォール設定先のVPCネットワークの指定
  network = google_compute_network.vpc.id
  # ファイアウォールの対象とする通信方向
  direction = "INGRESS" # 外から中への通信
  # 通信を許可するプロトコルとポート
  allow {
    # SSH通信を許可
    protocol = "tcp"
    ports    = ["22"]
  }
  # 対象のVMインスタンスのタグを指定する
  target_tags = ["ssh-server"]
  # 接続を許可するSSH接続元IPアドレス範囲の指定
  # 現在使用中のグローバルIPアドレスだけを許可する場合、
  # $ curl httpbin.org/ip で取得したIPアドレスを以下のように指定する
  # 例：123.123.123.123/32
  source_ranges = ["0.0.0.0/0"]
  # CloudLogggingにFlowLogを出力する設定
  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

# ユーザーに対するロールの付与
# 特定のGoogleアカウントにインスタンスへのSSH接続を許可する
resource "google_project_iam_binding" "gce_ssh_access_user" {
  depends_on = [google_project_service.apis]
  # プロジェクトIDの指定
  project = var.project_id
  # 割り当てるロール
  role = google_project_iam_custom_role.gce_ssh_access_role.id
  # 割り当て先の対象ユーザー
  members = var.gce_allow_ssh_user
}

# カスタムロールの作成
resource "google_project_iam_custom_role" "gce_ssh_access_role" {
  depends_on = [google_project_service.apis]
  # カスタムロールのID
  role_id = "CutomRole"
  # カスタムロールのタイトル
  title = var.project_id
  # 許可する権限：SSH接続を許可
  permissions = [
    "compute.projects.get",
    "compute.instances.get",
    "compute.instances.setMetadata",
    "iam.serviceAccounts.actAs",
  ]
}
