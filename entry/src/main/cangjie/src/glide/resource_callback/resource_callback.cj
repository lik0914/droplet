package glide.resource_callback

import glide.engine.cache.*
import glide.util.exceptions.*
import glide.load.*
import glide.add.*

from std import sync.*

public interface ResourceCallback <: Equatable<ResourceCallback> & Hashable & ToString {

  func onResourceReady(resource: Option<AnyGlideResource>, dataSource: DataSource, isLoadedFromAlternateCacheKey: Bool): Unit;

  func onLoadFailed(e: GlideException): Unit;

  func getLock(): ReentrantMutex;

  func toString(): String
}
