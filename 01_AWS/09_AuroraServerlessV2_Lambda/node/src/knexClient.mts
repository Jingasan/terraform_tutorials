import knex, { Knex } from "knex";

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
 * Knexのシングルトン管理クラス
 * APIコールの度に毎回コネクションを張ると、新しいIAM認証トークンの再発行や接続のコストがかかったり、
 * 接続プールが積み上がっていき、接続上限の問題が発生したりするため、DBとのコネクション管理はシングルトンにしておく。
 */
export class KnexClient {
  private static instance: Knex | null = null;
  private static tokenExpiration: number = 0;
  private static config: AuroraConfig;

  /**
   * シングルトンインスタンスの初期化
   * @param config DB接続設定
   */
  static initialize(config: AuroraConfig) {
    this.config = config;
  }

  /**
   * Knexのシングルトンインスタンスの取得
   * @returns Knexのシングルトンインスタンス
   */
  static async getInstance(): Promise<Knex> {
    // 新しいコネクションを生成
    this.instance = knex({
      client: "pg",
      connection: {
        host: this.config.host,
        port: this.config.port,
        user: this.config.username,
        password: this.config.password,
        database: this.config.database,
        ssl: this.config.ssl ? { rejectUnauthorized: false } : undefined,
      },
      pool: {
        max: 1, // 最大同時接続数
        min: 0, // 最小同時接続数
      },
    });

    console.log("New IAM token issued and Knex instance created.");

    return this.instance;
  }
}
