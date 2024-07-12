/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2023-2024. All rights resvered.
 */
 
package glide

public class MultiTransformation <: Transformation<PixelMap> {
    public var ID: String = "glide.MultiTransformation"

    public var transformations: ArrayList<PixelMapTransformation> = ArrayList<PixelMapTransformation>();

    public init(transformationList: ArrayList<PixelMapTransformation>) {
        if (transformationList.size > 0) {
            this.transformations = transformationList
        }
    }

    public func transform(resource: AnyGlideResource, outWidth: Int64, outHeight: Int64): AnyGlideResource {
        if (resource is GlideResource<PixelMap>) {
            let r: GlideResource<PixelMap> = (resource as GlideResource<PixelMap>).getOrThrow()
            return (transform(r, outWidth, outHeight) as AnyGlideResource).getOrThrow()
        } else {
            return resource
        }
    }

    public func transform(resource: GlideResource<PixelMap>, outWidth: Int64, outHeight: Int64): GlideResource<PixelMap> {
        var previous: GlideResource<PixelMap> = resource;

        for (i in 0..transformations.size) {
            var transformed: GlideResource<PixelMap> = transformations.get(i).getOrThrow().transform(previous, outWidth,
                outHeight);
            if (previous != resource && previous != transformed) {
                previous.recycle();
            }
            previous = transformed
        }
        return previous;
    }

    public func toString(): String {
        return "MultiTransformation(transformations=${hashCode()})";
    }

    public func hashCode(): Int64 {
        Utils.hashCodeWrite(ID, reset: true)
        for (i in 0..transformations.size) {
            Utils.hashCodeWrite(transformations.get(i).getOrThrow().hashCode())
        }
        return Utils.hashCodeFinish()
    }

    public operator func ==(that: AnyKey): Bool {
        if (that is MultiTransformation) {
            var other: MultiTransformation = (that as MultiTransformation).getOrThrow();
            if (transformations.size != other.transformations.size) {
                return false
            }
            for (i in 0..transformations.size) {
                if (transformations.get(i).getOrThrow() != other.transformations.get(i).getOrThrow()) {
                    return false
                }
            }
            return true
        } else {
            return false
        }
    }

    public operator func !=(that: AnyKey): Bool {
        if (that is MultiTransformation) {
            var other: MultiTransformation = (that as MultiTransformation).getOrThrow();
            if (transformations.size != other.transformations.size) {
                return true
            }
            for (i in 0..transformations.size) {
                if (transformations.get(i).getOrThrow() != other.transformations.get(i).getOrThrow()) {
                    return true
                }
            }
            return false
        } else {
            return true
        }
    }

    public func updateDiskCacheKey(md5: MD5) {
        for (i in 0..transformations.size) {
            transformations.get(i).getOrThrow().updateDiskCacheKey(md5);
        }
    }
}
