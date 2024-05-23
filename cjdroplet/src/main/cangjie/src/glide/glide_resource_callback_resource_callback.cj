package glide

from std import sync.*

public interface ResourceCallback <: Equatable<ResourceCallback> & Hashable & ToString {

  func onResourceReady(resource: Option<AnyGlideResource>, dataSource: DataSource, isLoadedFromAlternateCacheKey: Bool): Unit;

  func onLoadFailed(e: GlideException): Unit;

  func getLock(): ReentrantMutex;

  func toString(): String
}
