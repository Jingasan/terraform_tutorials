/**
 * AWS Backupの指定世代以降の古いをリカバリーポイントを削除する定期実行Lambda
 */
import * as sourceMapSupport from "source-map-support";
import * as Backup from "@aws-sdk/client-backup";
import * as SecretsManager from "@aws-sdk/client-secrets-manager";
import { Logger } from "@aws-lambda-powertools/logger";
sourceMapSupport.install();
const REGION = process.env.REGION || "ap-northeast-1";
const VAULT_NAME = process.env.VAULT_NAME;
const SECRET_NAME = process.env.SECRET_NAME;
const SERVICE_NAME = process.env.SERVICE_NAME;
const logger = new Logger({ serviceName: SERVICE_NAME });
const client = new Backup.BackupClient({ region: REGION });
const secretsManagerClient = new SecretsManager.SecretsManagerClient({
  region: REGION,
});

/**
 * SecretsManagerからシークレットおよび設定値を取得する
 * @returns シークレットおよび設定値
 */
const getSecrets = async (): Promise<
  | {
      keepGenerations: number;
      vaultNames: string[];
    }
  | undefined
> => {
  if (!SECRET_NAME) {
    logger.error("SECRET_NAME is not set");
    return undefined;
  }
  const command = new SecretsManager.GetSecretValueCommand({
    SecretId: SECRET_NAME,
  });
  const res = await secretsManagerClient.send(command);
  if (!res.SecretString) {
    logger.error("SecretString is not found");
    return undefined;
  }
  try {
    const secret = JSON.parse(res.SecretString);
    if (
      secret.keepGenerations === undefined ||
      secret.vaultNames === undefined
    ) {
      logger.error("keepGenerations or vaultNames is not found");
      return undefined;
    }
    return {
      keepGenerations: secret.keepGenerations,
      vaultNames: secret.vaultNames,
    };
  } catch (error) {
    logger.error("SecretString is not JSON format");
    return undefined;
  }
};

/**
 * Vaultに保存されたリカバリーポイント一覧の取得
 * @param backupVaultName ターゲットのVault名
 * @returns Vaultに保存されたリカバリーポイントの一覧
 */
const getRecoveryPointList = async (
  backupVaultName: string
): Promise<Backup.RecoveryPointByBackupVault[]> => {
  let recoveryPoints: Backup.RecoveryPointByBackupVault[] = [];
  let nextToken: string | undefined = undefined;
  try {
    do {
      const command = new Backup.ListRecoveryPointsByBackupVaultCommand({
        BackupVaultName: backupVaultName,
        NextToken: nextToken,
      });
      const res = await client.send(command);
      if (res.RecoveryPoints) {
        recoveryPoints = recoveryPoints.concat(res.RecoveryPoints);
      }
      nextToken = res.NextToken; // 次のページのトークンを取得
    } while (nextToken); // nextTokenがある限りループ
    return recoveryPoints;
  } catch (e) {
    logger.error(e);
    return [];
  }
};

/**
 * Vaultから指定のリカバリーポイントを削除
 * @param deleteTargetRecoveryPointARN 削除対象のリカバリーポイントのARN
 * @returns true:成功
 */
const deleteRecoveryPoint = async (deleteTargetRecoveryPointARN: string) => {
  try {
    const command = new Backup.DeleteRecoveryPointCommand({
      BackupVaultName: VAULT_NAME,
      RecoveryPointArn: deleteTargetRecoveryPointARN,
    });
    await client.send(command);
    return true;
  } catch (e) {
    logger.error(e);
    return false;
  }
};

/**
 * Vaultから各バックアップ対象のリソースごとに指定世代分を残し、古いバックアップをすべて削除するハンドラ
 * ただし、失敗したバックアップについては容量もないため、解析の用途で残す。
 * @param event EventBridgeイベント
 */
export const handler = async (event: any) => {
  logger.info(`Event: ${JSON.stringify(event, null, 2)}`);

  // シークレットおよび設定値を取得
  const secrets = await getSecrets();
  if (!secrets) return;

  // バックアップ先のVaultごとに処理を実施
  secrets.vaultNames.forEach(async (vaultName) => {
    logger.info(`Target vault: ${vaultName}`);

    // リカバリーポイントの一覧取得
    const recoveryPointList = await getRecoveryPointList(vaultName);
    if (!recoveryPointList.length) {
      logger.info("No recovery points found.");
      return;
    }

    // リソースIDごとにリカバリーポイントをグループ化
    const groupedByResource: Record<string, typeof recoveryPointList> = {};
    for (const point of recoveryPointList) {
      const resourceId = point.ResourceName ?? "unknown";
      if (!groupedByResource[resourceId]) {
        groupedByResource[resourceId] = [];
      }
      groupedByResource[resourceId].push(point);
    }

    // 各リソースIDごとに処理を実施
    for (const [_, points] of Object.entries(groupedByResource)) {
      // 作成日時順にソート
      const sortedPoints = points.sort(
        (a, b) =>
          (b.CreationDate?.getTime() ?? 0) - (a.CreationDate?.getTime() ?? 0)
      );
      // ステータスがCOMPLETEDなリカバリーポイントを取得
      const completedPoints = sortedPoints.filter(
        (point) => point.Status === Backup.RecoveryPointStatus.COMPLETED
      );
      // 保持する世代数よりもリカバリーポイントが少ない場合は削除しない
      if (completedPoints.length <= secrets.keepGenerations) {
        logger.info(
          `Skipping deletion for resource: ${completedPoints[0]?.ResourceType} ${completedPoints[0]?.ResourceName}, as it has only ${completedPoints.length} recovery points (keep ${secrets.keepGenerations}).`
        );
        continue;
      }

      // 最新指定世代分を抜いた古いCOMPLETEDリカバリーポイントを削除
      const toDelete = completedPoints.slice(secrets.keepGenerations);
      logger.info(
        `Deleting ${toDelete.length} old recovery points for resource: ${completedPoints[0]?.ResourceType} ${completedPoints[0]?.ResourceName}`
      );
      // ステータスがCOMPLETEDである最新のリカバリーポイントまでを残し、それ以前の古いリカバリーポイントは削除
      if (toDelete.length > 0) {
        await Promise.allSettled(
          toDelete.map(async (recoveryPoint) => {
            if (recoveryPoint.RecoveryPointArn) {
              const res = await deleteRecoveryPoint(
                recoveryPoint.RecoveryPointArn
              );
              if (res) {
                logger.info(
                  `Succeeded to delete old recovery point: ${recoveryPoint.RecoveryPointArn}`
                );
              } else {
                logger.error(
                  `Failed to delete old recovery point: ${recoveryPoint.RecoveryPointArn}`
                );
              }
            }
          })
        );
      }
    }
  });
  logger.info("Finished to delete old recovery points.");
};
