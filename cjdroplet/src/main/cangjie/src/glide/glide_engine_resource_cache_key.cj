/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2023-2024. All rights resvered.
 */
 
package glide

public class ResourceCacheKey <: AnyKey {

    private let arrayPool: ArrayPool
    public let sourceKey: AnyKey
    public let signature: AnyKey
    public let width: Int64
    public let height: Int64
    public let decodedResourceClass: TransformationKey
    public let options: GlideOptions
    public let transformation: AnyTransformation

    public init(
        arrayPool: ArrayPool,
        sourceKey: AnyKey,
        signaturecj: AnyKey,
        width: Int64,
        height: Int64,
        appliedTransformationcj: AnyTransformation,
        decodedResourceClass: TransformationKey,
        options: GlideOptions
    ) {
        this.arrayPool = arrayPool
        this.sourceKey = sourceKey
        this.signature = signaturecj
        this.width = width
        this.height = height
        this.transformation = appliedTransformationcj
        this.decodedResourceClass = decodedResourceClass
        this.options = options
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
        result = 31 * result + signature.hashCode()
        result = 31 * result + width
        result = 31 * result + height
        result = 31 * result + transformation.hashCode()
        result = 31 * result + decodedResourceClass.hashCode()
        result = 31 * result + options.hashCode()
        return result;
    }

    public func updateDiskCacheKey(md5: MD5): Unit {
        // 宽高各占2位
        var dimensions: Array<UInt8> = arrayPool.getExact(4);

        AppLog.error("updateDiskCacheKey dimensions length: ${dimensions.size} ${width} ${height}")

        if (width == Downsampler.SIZE_ORIGINAL) {
            dimensions[0] = 0xFF
            dimensions[1] = 0xFF
        } else {
            dimensions[0] = UInt8(width & 0xFF)
            dimensions[1] = UInt8(width >> 8)
        }

        if (height == Downsampler.SIZE_ORIGINAL) {
            dimensions[2] = 0xFF
            dimensions[3] = 0xFF
        } else {
            dimensions[2] = UInt8(height & 0xFF)
            dimensions[3] = UInt8(height >> 8)
        }

        signature.updateDiskCacheKey(md5);
        sourceKey.updateDiskCacheKey(md5);

        md5.MD5Update(dimensions)

        transformation.updateDiskCacheKey(md5);
        options.updateDiskCacheKey(md5);

        md5.MD5Update([UInt8(decodedResourceClass.tType)])

        arrayPool.put(dimensions);
        md5.MD5Update(decodedResourceClass.hashCode().toString().toArray())
    }



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
