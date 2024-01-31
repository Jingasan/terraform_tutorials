#============================================================
# Cloud Build
#============================================================

# ビルドトリガーの作成
resource "google_cloudbuild_trigger" "code_push_trigger" {
  depends_on = [google_project_service.apis]
  # トリガーの名前
  name = var.project_id
  # リージョン
  location = "global"
  # トリガーの無効化(false:無効化しない)
  disabled = false
  # ビルドトリガー
  trigger_template {
    # トリガー対象のリポジトリ
    repo_name = google_sourcerepo_repository.repo.name
    # トリガー
    # branch_name: 指定のブランチに変更があった場合にビルドを実行
    # tag_name: 指定のタグが追加された場合にビルドを実行
    branch_name = "master"
  }
  # ビルド設定ファイルまでのパス
  filename = "cloudbuild.yaml"
  # ビルドから除外するファイル群
  ignored_files = []
  # ビルドに含めるファイル群
  included_files = []
  # ビルド承認の設定
  approval_config {
    # ビルドに承認が必要かどうか(false(default):不要)
    approval_required = false
  }
  # ビルド設定ファイルに与える環境変数(Substitutions data)
  substitutions = {
    _ENV = "VALUE"
  }
  # ビルド処理のタイムアウトの設定
  timeouts {}
  # 説明文
  description = var.project_id
  # タグ
  tags = [var.project_id]
}
