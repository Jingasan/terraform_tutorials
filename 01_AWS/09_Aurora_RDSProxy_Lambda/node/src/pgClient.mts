import { Pool } from "pg";

/**
 * DB接続設定
 */
interface AuroraConfig {
  host: string;
  port: number;
  region: string;
  database: string;
  username: string;
  password: string;
  ssl?: boolean;
}

/**
 * PGのシングルトン管理クラス
 * APIコールの度に毎回コネクションを張ると、接続コストがかかったり、
 * 接続プールが積み上がっていき、接続上限の問題が発生したりするため、DBとのコネクション管理はシングルトンにしておく。
 */
export class PgClient {
  private static pool: Pool | null = null;
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
    // 新しいPoolを生成
    this.pool = new Pool({
      host: this.config.host,
      port: this.config.port,
      user: this.config.username,
      password: this.config.password,
      database: this.config.database,
      ssl: this.config.ssl ? { rejectUnauthorized: false } : undefined,
      max: 1, // 最大同時接続数
      min: 0, // 最小同時接続数
      idleTimeoutMillis: 10_000,
    });

    console.log("New IAM token issued and pg Pool created.");

    return this.pool;
  }
}
