import knex, { Knex } from "knex";
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
    const now = Date.now();

    // IAM認証トークンが有効期限内なら再利用（14分以上使用している場合は再接続）
    if (this.instance && now < this.tokenExpiration - 60_000) {
      return this.instance;
    }

    // RDS接続のためのIAM認証トークンを取得
    const token = await generateIAMAuthToken({
      host: this.config.host,
      port: this.config.port,
      region: this.config.region,
      username: this.config.username,
    });

    // 古いコネクションを削除
    if (this.instance) {
      await this.instance.destroy();
    }

    // 新しいコネクションを生成
    this.instance = knex({
      client: "pg",
      connection: {
        host: this.config.host,
        port: this.config.port,
        user: this.config.username,
        password: token,
        database: this.config.database,
        ssl: this.config.ssl ? { rejectUnauthorized: false } : undefined,
      },
      pool: {
        max: 1, // 最大同時接続数
        min: 0, // 最小同時接続数
      },
    });

    // トークンの有効期限を15分に設定
    this.tokenExpiration = now + 15 * 60 * 1000;

    console.log("New IAM token issued and Knex instance created.");

    return this.instance;
  }
}
