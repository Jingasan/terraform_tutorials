#============================================================
# WAF (IPアドレス制限)
#============================================================

# セキュリティポリシーの追加
resource "azurerm_cdn_frontdoor_security_policy" "example" {
  # セキュリティポリシー名
  name = "IPRestriction"
  # セキュリティポリシーの割り当て先となるFrontDoorのID
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.frontdoor.id
  # セキュリティポリシー
  security_policies {
    firewall {
      # セキュリティポリシーとなるWAFのID
      cdn_frontdoor_firewall_policy_id = azurerm_cdn_frontdoor_firewall_policy.example.id
      # 割り当て先
      association {
        # ドメイン
        domain {
          cdn_frontdoor_domain_id = azurerm_cdn_frontdoor_endpoint.endpoint.id
        }
        # WAFの対象とするパス
        patterns_to_match = ["/*"]
      }
    }
  }
}

# WAFの作成
resource "azurerm_cdn_frontdoor_firewall_policy" "example" {
  # WAF名
  name = var.project_name
  # リソースグループ
  resource_group_name = azurerm_resource_group.rg.name
  # プラン
  sku_name = azurerm_cdn_frontdoor_profile.frontdoor.sku_name
  # WAFの有効化
  enabled = true
  # FrontDoor Firewall Policy mode
  # Prevention:アクセスを防ぐ/Detection:アクセスログを監視するだけ
  mode = "Prevention"
  # カスタムルールの設定
  custom_rule {
    # カスタムルール名
    name = "AllowIPRule"
    # カスタムルールの有効化
    enabled = true
    # ルールの種類
    type = "MatchRule"
    # 優先度
    priority = 1
    # 条件
    match_condition {
      # 一致の種類
      operator = "IPMatch"
      # 一致変数
      match_variable = "RemoteAddr"
      # 演算 (false:含まれる/true:次の値を含まない)
      negation_condition = true
      # IPアドレスまたは範囲
      match_values = var.waf_allow_ips
    }
    # 結果 (Block:トラフィックを拒否する/Allow:トラフィックを許可する)
    action = "Block"
  }
  # タグ
  tags = {
    Name = var.project_name
  }
}
