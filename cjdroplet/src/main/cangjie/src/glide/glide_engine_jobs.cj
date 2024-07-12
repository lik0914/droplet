/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2023-2024. All rights resvered.
 */
 
package glide

from ohos import base.*

public class Jobs {
  private let jobs: HashMap<AnyKey, EngineJob> = HashMap<AnyKey, EngineJob>();
  private let onlyCacheJobs: HashMap<AnyKey, EngineJob> = HashMap<AnyKey, EngineJob>();

  public func getAll(): HashMap<AnyKey, EngineJob> {
    return jobs;
  }

  public func get(key: AnyKey, onlyRetrieveFromCache: Bool): Option<EngineJob> {
    let oo: HashMap<AnyKey, EngineJob> = getJobMap(onlyRetrieveFromCache)
    let o: Option<EngineJob> = oo.get(key);
    AppLog.error("jobs size : ${oo.size}")
    if(match(o) {
      case Some(x) => true
      case _ => false
    }) {
      AppLog.error("jobs get true")
    } else {
      AppLog.error("jobs get false")
    }
    return o
  }

  public func put(key: AnyKey, job: EngineJob): Unit {
    // AppLog.error("jobs put  ${key}")
    getJobMap(job.onlyRetrieveFromCache).put(key, job);
  }

  public func removeIfCurrent(key: AnyKey, expected: EngineJob): Unit {
    // AppLog.error("jobs removeIfCurrent  ${key}")
    var jobMap: HashMap<AnyKey, EngineJob> = getJobMap(expected.onlyRetrieveFromCache);
    if (Some(expected) == jobMap.get(key)) {
      jobMap.remove(key);
    }
  }

  private func getJobMap(onlyRetrieveFromCache: Bool): HashMap<AnyKey, EngineJob> {
    return if(onlyRetrieveFromCache) {
        onlyCacheJobs 
    } else {
        jobs
    }
  }
}
