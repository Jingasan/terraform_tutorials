import * as GCS from "@google-cloud/storage";

export class GCSClient {
  private gcsClient = new GCS.Storage({
    credentials: JSON.parse(process.env.CREDENTIALS), // PresignedURLを取得するために必要
  });

  /**
   * コンストラクタ
   */
  constructor() {}

  /**
   * バケットの作成
   * @param bucketName バケット名
   * @returns true:成功/false:失敗
   */
  public createBucket = async (bucketName: string): Promise<boolean> => {
    const metadata: GCS.CreateBucketRequest = {
      location: "asia-northeast1", // ロケーションの設定
      storageClass: "Standard", // ストレージクラスの設定
      cors: [
        // CORSの設定
        {
          origin: ["*"],
          method: ["GET", "HEAD", "PUT", "POST", "DELETE"],
          responseHeader: ["*"],
          maxAgeSeconds: 3600,
        },
      ],
      versioning: {
        // バージョニングの設定
        enabled: false,
      },
    };
    try {
      const res = await this.gcsClient.createBucket(bucketName, metadata);
      console.log(res);
      return true;
    } catch (err) {
      console.error(err);
      return false;
    }
  };

  /**
   * バケット一覧の取得
   * @returns
   */
  public listBuckets = async (): Promise<string[]> => {
    try {
      const [buckets] = await this.gcsClient.getBuckets();
      const bucketList: string[] = [];
      buckets.forEach((bucket: any) => {
        bucketList.push(bucket.name);
      });
      return bucketList;
    } catch (err) {
      console.error(err);
      return [];
    }
  };

  /**
   * バケットの削除
   * @param bucketName バケット名
   * @returns true:成功/false:失敗
   */
  public deleteBucket = async (bucketName: string): Promise<boolean> => {
    try {
      await this.gcsClient.bucket(bucketName).delete({ ignoreNotFound: true });
      return true;
    } catch (err) {
      console.error(err);
      return false;
    }
  };

  /**
   * オブジェクトの保存
   * @param bucketName バケット名
   * @param dstPath 保存先パス
   * @param object 保存するオブジェクト
   * @returns true:成功/false:失敗
   */
  public putObject = async (
    bucketName: string,
    dstPath: string,
    object: string
  ): Promise<boolean> => {
    try {
      await this.gcsClient.bucket(bucketName).file(dstPath).save(object);
      return true;
    } catch (err) {
      console.error(err);
      return false;
    }
  };

  /**
   * オブジェクト一覧の取得
   * @param bucketName バケット名
   * @param prefix オブジェクト一覧を取得するフォルダのパス
   * @param delimiter デリミタ
   * @returns オブジェクト一覧
   */
  public listObjects = async (
    bucketName: string,
    prefix?: string,
    delimiter?: string
  ): Promise<string[]> => {
    const objectList: string[] = [];
    try {
      const [objects] = await this.gcsClient
        .bucket(bucketName)
        .getFiles({ prefix, delimiter });
      objects.forEach((file) => {
        objectList.push(file.name);
      });
    } catch (err) {
      console.error(err);
    }
    return objectList;
  };

  /**
   * オブジェクトの取得
   * @param bucketName バケット名
   * @param path 取得対象のオブジェクトのパス
   * @returns オブジェクト/false:取得失敗
   */
  public getObject = async (
    bucketName: string,
    path: string
  ): Promise<string | false> => {
    try {
      const data = await this.gcsClient
        .bucket(bucketName)
        .file(path)
        .download();
      return data[0].toString();
    } catch (err) {
      console.error(err);
      return false;
    }
  };

  /**
   * オブジェクトの削除
   * @param bucketName バケット名
   * @param path 削除対象オブジェクトのパス
   * @returns true:成功/false:失敗
   */
  public deleteObject = async (
    bucketName: string,
    path: string
  ): Promise<boolean> => {
    try {
      await this.gcsClient
        .bucket(bucketName)
        .file(path)
        .delete({ ignoreNotFound: true });
      return true;
    } catch (err) {
      console.error(err);
      return false;
    }
  };

  /**
   * ファイルアップロード用のPresignedURLの取得
   * @param bucketName バケット名
   * @param path 対象のパス
   * @param expires 有効時間[sec]
   * @returns PresignedURL
   */
  public getPutPresignedURL = async (
    bucketName: string,
    path: string,
    expires: number
  ): Promise<string | false> => {
    const cfg: GCS.GetSignedUrlConfig = {
      version: "v2",
      action: "write",
      expires: Date.now() + expires * 1000, // 有効期限[ms]
    };
    try {
      const [url] = await this.gcsClient
        .bucket(bucketName)
        .file(path)
        .getSignedUrl(cfg);
      return url;
    } catch (err) {
      console.error(err);
      return false;
    }
  };
}
