import { Pool } from "pg";
import { generateIAMAuthToken } from "./generateAuthToken.mjs";

/**
 * DB接続設定
 */
interface AuroraConfig {
  host: string;
  port: number;
  region: string;
  database: string;
  username: string;
  ssl?: boolean;
}

/**
 * PGのシングルトン管理クラス
 * APIコールの度に毎回コネクションを張ると、新しいIAM認証トークンの再発行や接続のコストがかかったり、
 * 接続プールが積み上がっていき、接続上限の問題が発生したりするため、DBとのコネクション管理はシングルトンにしておく。
 */
export class PgClient {
  private static pool: Pool | null = null;
  private static tokenExpiration = 0;
  private static config: AuroraConfig;

  /**
   * シングルトンインスタンスの初期化
   * @param config DB接続設定
   */
  static initialize(config: AuroraConfig) {
    this.config = config;
  }

  /**
   * コネクションプールの取得
   * @returns コネクションプール
   */
  static async getPool(): Promise<Pool> {
    const now = Date.now();

    // 有効期限内なら再利用（14分以上使用している場合は再接続）
    if (this.pool && now < this.tokenExpiration - 60_000) {
      return this.pool;
    }

    // RDS接続のためのIAM認証トークンを取得
    const token = await generateIAMAuthToken({
      hostname: this.config.host,
      port: this.config.port,
      region: this.config.region,
      username: this.config.username,
    });

    // 古いPoolをクローズ
    if (this.pool) await this.pool.end();

    // 新しいPoolを生成
    this.pool = new Pool({
      host: this.config.host,
      port: this.config.port,
      user: this.config.username,
      password: token,
      database: this.config.database,
      ssl: this.config.ssl ? { rejectUnauthorized: false } : undefined,
      max: 1, // 最大同時接続数
      min: 0, // 最小同時接続数
      idleTimeoutMillis: 10_000,
    });

    // トークンの有効期限を15分に設定
    this.tokenExpiration = now + 15 * 60 * 1000;

    console.log("New IAM token issued and pg Pool created.");

    return this.pool;
  }
}
