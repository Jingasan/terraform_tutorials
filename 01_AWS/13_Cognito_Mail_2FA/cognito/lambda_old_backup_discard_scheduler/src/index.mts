/**
 * AWS Backupの古いをリカバリーポイントを削除する定期実行Lambda
 */
import * as Backup from "@aws-sdk/client-backup";
import { Logger } from "@aws-lambda-powertools/logger";
const REGION = process.env.REGION || "ap-northeast-1";
const VAULT_NAME = process.env.VAULT_NAME;
const SERVICE_NAME = process.env.SERVICE_NAME;
const logger = new Logger({ serviceName: SERVICE_NAME });
const client = new Backup.BackupClient({ region: REGION });

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
 * Vaultから各バックアップ対象のリソースごとに最新のバックアップを１つ残して古いバックアップをすべて削除するハンドラ
 * ただし、失敗したバックアップについては容量もないため、解析の用途で残す。
 * @param event EventBridgeイベント
 */
export const handler = async (event: any) => {
  logger.info(`Event: ${JSON.stringify(event, null, 2)}`);

  // リカバリーポイントの一覧取得
  const recoveryPointList = await getRecoveryPointList(VAULT_NAME);
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
    // 最新のCOMPLETEDなリカバリーポイントを取得
    const latestCompletedIdx = sortedPoints.findIndex(
      (point) => point.Status === Backup.RecoveryPointStatus.COMPLETED
    );
    if (latestCompletedIdx === -1) {
      logger.info(
        `No completed recovery points found for resource: ${sortedPoints[0].ResourceType} ${sortedPoints[0].ResourceName}`
      );
      return;
    }
    // ステータスがCOMPLETEDである最新のリカバリーポイント情報
    logger.info(
      `[Newest recovery point info]
idx: ${latestCompletedIdx}
RecoveryPointARN: ${sortedPoints[latestCompletedIdx].RecoveryPointArn}
CreationDate: ${sortedPoints[latestCompletedIdx].CreationDate}
Status: ${sortedPoints[latestCompletedIdx].Status}
StatusMessage: ${sortedPoints[latestCompletedIdx].StatusMessage}
BackupSize(Bytes): ${sortedPoints[latestCompletedIdx].BackupSizeInBytes}
ResourceType: ${sortedPoints[latestCompletedIdx].ResourceType}
ResourceName: ${sortedPoints[latestCompletedIdx].ResourceName}
`
    );
    // 最新のCOMPLETEDリカバリーポイントを除いた古いものを削除
    const toDelete = sortedPoints.filter(
      (_, idx) => idx !== latestCompletedIdx
    );
    logger.info(
      `Deleting ${toDelete.length} old recovery points for resource: ${sortedPoints[latestCompletedIdx].ResourceType} ${sortedPoints[latestCompletedIdx].ResourceName}`
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
  logger.info("Finished to delete old recovery points.");
};
