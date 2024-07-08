package glide


public class ResourceCacheKey <: AnyKey {
    // 缓存 decodedResourceClass  可能不需要做
//   private static let RESOURCE_CLASS_BYTES: LruCache<ResourceTypeClass, String> = LruCache<ResourceTypeClass, String>(50);

  private let arrayPool: ArrayPool;
  public let sourceKey: AnyKey;
  public let signature: AnyKey;
  public let width: Int64;
  public let height: Int64;
  public let decodedResourceClass: TransformationKey;
  public let options: GlideOptions;
  public let transformation: AnyTransformation;

  public init(
      arrayPool: ArrayPool,
      sourceKey: AnyKey,
      signaturecj: AnyKey,
      width: Int64,
      height: Int64,
      appliedTransformationcj: AnyTransformation,
      decodedResourceClass: TransformationKey,
      options: GlideOptions) {
    this.arrayPool = arrayPool;
    this.sourceKey = sourceKey;
    this.signature = signaturecj;
    this.width = width;
    this.height = height;
    this.transformation = appliedTransformationcj;
    this.decodedResourceClass = decodedResourceClass;
    this.options = options;
  }

    public operator func ==(that: AnyKey): Bool {
        return equals(that)
    }

    public operator func !=(that: AnyKey): Bool {
        return !equals(that)
    }

  public func equals(o: AnyKey) {
    if (o is ResourceCacheKey) {
      var other: ResourceCacheKey = (o as ResourceCacheKey).getOrThrow();
      return height == other.height
          && width == other.width
          && transformation == other.transformation
          && decodedResourceClass == other.decodedResourceClass
          && sourceKey == other.sourceKey
          && signature == other.signature
          && options == other.options
    }
    return false;
  }

  public func hashCode(): Int64 {
    var result = sourceKey.hashCode();
    result = 31 * result + signature.hashCode();
    result = 31 * result + width;
    result = 31 * result + height;
    // if (transformation != null) {
      result = 31 * result + transformation.hashCode();
    // }
    result = 31 * result + decodedResourceClass.hashCode();
    result = 31 * result + options.hashCode();
    return result;
  }

  public func updateDiskCacheKey(md5: MD5): Unit {
    // byte[] dimensions = arrayPool.getExact(8, byte[].class);
    // 宽高各占2位
    var dimensions: Array<UInt8> = arrayPool.getExact(4);

    AppLog.error("updateDiskCacheKey dimensions length: ${dimensions.size} ${width} ${height}")

    // ByteBuffer.wrap(dimensions).putInt(width).putInt(height).array();
    if(width == Downsampler.SIZE_ORIGINAL){
        dimensions[0] = 0xFF
        dimensions[1] = 0xFF
    }else{
        dimensions[0] = UInt8(width & 0xFF)
        dimensions[1] = UInt8(width >> 8)
    }

    if(height == Downsampler.SIZE_ORIGINAL){
        dimensions[2] = 0xFF
        dimensions[3] = 0xFF
    }else{
        dimensions[2] = UInt8(height & 0xFF)
        dimensions[3] = UInt8(height >> 8)
    }

    signature.updateDiskCacheKey(md5);
    sourceKey.updateDiskCacheKey(md5);

    // md5.MD5Update(width.toString().toUtf8Array());
    // md5.MD5Update(height.toString().toUtf8Array());
    md5.MD5Update(dimensions)

    // if (transformation != null) {
      transformation.updateDiskCacheKey(md5);
    // }
    options.updateDiskCacheKey(md5);

    // 缓存 decodedResourceClass(TransformationKey)
    // md5.MD5Update(getResourceClassBytes().toUtf8Array());
    md5.MD5Update([UInt8(decodedResourceClass.tType)])

    // arrayPool
    arrayPool.put(dimensions);

    //适配
    //md5.MD5Update(decodedResourceClass.hashCode().toString().toUtf8Array())
    md5.MD5Update(decodedResourceClass.hashCode().toString().toArray())
  }

    // TODO 缓存 decodedResourceClass
//   private func getResourceClassBytes(): String {
//     var result: Option<String> = RESOURCE_CLASS_BYTES.get(decodedResourceClass);
//     if (match(result) {
//         case Some(x) => false
//         case _ => true
//     }) {
//       var r: String = decodedResourceClass.hashCode();
//       result = Some(r)
//       RESOURCE_CLASS_BYTES.put(decodedResourceClass, r);
//     }
//     return result.getOrThrow();
//   }

  public func toString(): String {
    return """
        ResourceCacheKey{sourceKey=${sourceKey}
        , signature=${signature}
        , width=${width}
        , height=${height}
        , decodedResourceClass=${decodedResourceClass}
        , transformation=${transformation}
        , options=${options}}""";
  }
}
