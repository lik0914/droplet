/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2023-2024. All rights resvered.
 */
 
package droplet.droplet

public class EngineKey <: AnyKey {
  private let model: Model;
  private let width: Int64;
  private let height: Int64;
  private let resourceTypeClass: ResourceTypeClass;
  private let transformationKey: TransformationKey;
  private let signature: AnyKey;
  private let transformations: CachedHashCodeArrayMap<TransformationKey, AnyKey>;
  private let options: DropletOptions;
  private var hashCodeLocal: Int64 = 0;

  EngineKey(
      model: Model,
      signature: AnyKey,
      width: Int64,
      height: Int64,
      transformations: CachedHashCodeArrayMap<TransformationKey, AnyKey>,
      resourceTypeClass: ResourceTypeClass,
        transformationKey: TransformationKey,
      options: DropletOptions) {
    this.model = model
    this.signature = signature
    this.width = width;
    this.height = height;
    this.transformations = transformations;
    this.resourceTypeClass = resourceTypeClass;
    this.transformationKey = transformationKey;
    this.options = options;
  }

  public override func hashCode(): Int64 {
    if (hashCodeLocal == 0) {
      Utils.hashCodeWrite(model.hashCode(), reset: true)
      Utils.hashCodeWrite(signature.hashCode())
      Utils.hashCodeWrite(width)
      Utils.hashCodeWrite(height)
      Utils.hashCodeWrite(transformations.hashCode())
      Utils.hashCodeWrite(resourceTypeClass.hashCode())
      Utils.hashCodeWrite(transformationKey.hashCode())
      Utils.hashCodeWrite(options.hashCode())
      hashCodeLocal = Utils.hashCodeFinish()
      // hashCodeLocal = model.hashCode();
      // hashCodeLocal = 31 * hashCodeLocal + signature.hashCode();
      // hashCodeLocal = 31 * hashCodeLocal + width;
      // hashCodeLocal = 31 * hashCodeLocal + height;
      // hashCodeLocal = 31 * hashCodeLocal + transformations.hashCode();
      // hashCodeLocal = 31 * hashCodeLocal + resourceTypeClass.hashCode();
      // hashCodeLocal = 31 * hashCodeLocal + transformationKey.hashCode();
      // hashCodeLocal = 31 * hashCodeLocal + options.hashCode();
    }
    // AppLog.error("engine key hashCode ${hashCodeLocal}")
    return hashCodeLocal;
  }

    public operator func ==(that: AnyKey): Bool {
        return equals(that)
    }

    public operator func !=(that: AnyKey): Bool {
        return !equals(that)
    }

  public func equals(o: AnyKey): Bool {
    // AppLog.error("engine key equals")
    if (o is EngineKey) {
      var other: EngineKey = (o as EngineKey).getOrThrow();
      // AppLog.error("engine key equals options: ${options}  other options: ${other.options}  equals: ${options == other.options}")
      return model == other.model && 
          signature == other.signature && 
          height == other.height && 
          width == other.width && 
          transformations == other.transformations && 
          resourceTypeClass == other.resourceTypeClass && 
          transformationKey == other.transformationKey && 
          options == other.options
    }
    return false;
  }

  public func toString(): String {
    return """
        EngineKey{model=${model},
        width=${width},
        height=${height},
        resourceTypeClass=${resourceTypeClass},
        transformationKey=${transformationKey},
        signature=${signature},
        hashCode=${hashCodeLocal},
        transformations=${transformations},
        options=${options}}""";
  }

  public func updateDiskCacheKey(md5: MD5): Unit {
    throw Exception("droplet not updateDiskCacheKey error")
  }
}
