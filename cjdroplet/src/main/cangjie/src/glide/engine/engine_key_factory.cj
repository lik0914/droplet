package glide.engine

public class EngineKeyFactory {

  public func buildKey(
      model: Model,
      signature: AnyKey,
      width: Int64,
      height: Int64,
      transformations: CachedHashCodeArrayMap<TransformationKey, AnyKey>,
      resourceTypeClass: ResourceTypeClass,
      transformationKey: TransformationKey,
      options: GlideOptions): EngineKey {
    return EngineKey(model, signature, width, height, transformations, resourceTypeClass, transformationKey, options);
  }
}
