/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2023-2024. All rights resvered.
 */
 
package droplet.droplet

public class EngineKeyFactory {

  public func buildKey(
      model: Model,
      signature: AnyKey,
      width: Int64,
      height: Int64,
      transformations: CachedHashCodeArrayMap<TransformationKey, AnyKey>,
      resourceTypeClass: ResourceTypeClass,
      transformationKey: TransformationKey,
      options: DropletOptions): EngineKey {
    return EngineKey(model, signature, width, height, transformations, resourceTypeClass, transformationKey, options);
  }
}
