/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2023-2024. All rights resvered.
 */
 
package droplet.droplet


public interface ResourceCallback <: Equatable<ResourceCallback> & Hashable & ToString {

  func onResourceReady(resource: Option<AnyDropletResource>, dataSource: DataSource, isLoadedFromAlternateCacheKey: Bool): Unit;

  func onLoadFailed(e: DropletException): Unit;

  func getLock(): ReentrantMutex;

  func toString(): String
}
