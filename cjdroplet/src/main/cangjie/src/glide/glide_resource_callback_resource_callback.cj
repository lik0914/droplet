/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2023-2024. All rights resvered.
 */
 
package glide

from std import sync.*

public interface ResourceCallback <: Equatable<ResourceCallback> & Hashable & ToString {

  func onResourceReady(resource: Option<AnyGlideResource>, dataSource: DataSource, isLoadedFromAlternateCacheKey: Bool): Unit;

  func onLoadFailed(e: GlideException): Unit;

  func getLock(): ReentrantMutex;

  func toString(): String
}
