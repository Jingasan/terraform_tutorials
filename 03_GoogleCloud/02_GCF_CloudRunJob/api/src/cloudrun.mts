import { randomUUID } from "crypto";
import * as GCR from "@google-cloud/run";

export class GCRJobClient {
  private gcrJobClient = new GCR.JobsClient();
  private gcrExecutionJobClient = new GCR.ExecutionsClient();

  /**
   * ジョブの実行
   * @param jobId 実行対象のジョブID
   * @returns true:成功/false:失敗
   */
  public runJob = async (jobId: string): Promise<boolean> => {
    try {
      const [res] = await this.gcrJobClient.runJob({
        name: jobId,
      });
      console.log(JSON.stringify(res.result, null, "  "));
      return true;
    } catch (err) {
      console.error(err);
      return false;
    }
  };

  /**
   * ジョブ一覧の取得
   * @param projectId プロジェクトID
   * @param region リージョン
   * @returns ジョブ一覧
   */
  public listJobs = async (projectId: string, region: string) => {
    try {
      const list: string[] = [];
      const iterable = this.gcrJobClient.listJobsAsync({
        parent: `projects/${projectId}/locations/${region}`,
      });
      for await (const response of iterable) {
        list.push(response.name);
      }
      return list;
    } catch (err) {
      console.error(err);
      return [];
    }
  };

  /**
   * ジョブの実行中のタスク一覧取得
   * @param jobId ジョブID
   * @returns 実行中のタスク一覧
   */
  public listJobTask = async (jobId: string): Promise<string[]> => {
    const list: string[] = [];
    try {
      const iterable = this.gcrExecutionJobClient.listExecutionsAsync({
        parent: jobId,
      });
      for await (const response of iterable) {
        if (response.reconciling || response.runningCount > 0)
          list.push(response.name);
      }
      return list;
    } catch (err) {
      console.error(err);
      return [];
    }
  };

  /**
   * 実行中のタスクのキャンセル
   * @param taskId 実行中のタスクID
   * @returns true:成功/false:失敗
   */
  public cancelJobTask = async (taskId: string): Promise<boolean> => {
    try {
      await this.gcrExecutionJobClient.cancelExecution({
        name: taskId,
      });
      return true;
    } catch (err) {
      console.error(err);
      return false;
    }
  };
}
