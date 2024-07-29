/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2023-2024. All rights resvered.
 */
 
package droplet.droplet

public class DrawableTransformation <: Transformation<PixelMapDrawable> {

  private let wrapped: Transformation<PixelMap>;
  private let isRequired: Bool;

  public init(wrapped: Transformation<PixelMap>, isRequired: Bool) {
    this.wrapped = wrapped;
    this.isRequired = isRequired;
  }

  public func asPixelMapDrawable(): Transformation<PixelMapDrawable> {
    return ((this as AnyTransformation).getOrThrow() as Transformation<PixelMapDrawable>).getOrThrow();
  }

  public func transform(resource: AnyDropletResource, outWidth: Int64, outHeight: Int64): AnyDropletResource {
    if(resource is DropletResource<PixelMapDrawable>) {
      let r: DropletResource<PixelMapDrawable> = (resource as DropletResource<PixelMapDrawable>).getOrThrow()
      return (transform(r, outWidth, outHeight) as AnyDropletResource).getOrThrow()
    } else {
      return resource
    }
  }

  public func transform(resource: DropletResource<PixelMapDrawable>, outWidth: Int64, outHeight: Int64): DropletResource<PixelMapDrawable> {
    // BitmapPool bitmapPool = Droplet.get(context).getBitmapPool();
    let drawable: PixelMapDrawable = resource.get();
    // Drawable -> PixelMap DrawableToBitmapConverter.convert(bitmapPool, drawable, outWidth, outHeight);
    let pixelMap: PixelMap = drawable.getPixelMap() 
    let bitmapResourceToTransform: DropletResource<PixelMap> = PixelMapResource.obtain(pixelMap)
    // if (bitmapResourceToTransform == null) {
    //   if (isRequired) {
    //     throw new IllegalArgumentException("Unable to convert " + drawable + " to a Bitmap");
    //   } else {
    //     return resource;
    //   }
    // }
    let transformedBitmapResource: DropletResource<PixelMap> = wrapped.transform(bitmapResourceToTransform, outWidth, outHeight);

    // if (transformedBitmapResource.equals(bitmapResourceToTransform)) {
    //   transformedBitmapResource.recycle();
    //   return resource;
    // } else {
      return newDrawableResource(transformedBitmapResource);
    // }
  }

  // It's clearer to cast the result in a separate line from obtaining it.
  private func newDrawableResource(transformed: DropletResource<PixelMap>): DropletResource<PixelMapDrawable> {
    let pixelMap: PixelMap = transformed.get()
    let drawable: PixelMapDrawable = PixelMapDrawable(pixelMap)
    
    return PixelMapDrawableResource.obtain(drawable)
  }

  public func updateDiskCacheKey(md5: MD5) {
      wrapped.updateDiskCacheKey(md5);
  }

  public func toString(): String {
    return "DrawableTransformation: ${wrapped.toString()}"
  }

  public func hashCode(): Int64 {
    return wrapped.hashCode();
  }

  public operator func ==(that: AnyKey): Bool {
    // println("DrawableTransformation == :")
    if(that is DrawableTransformation) {
        let other: DrawableTransformation = (that as DrawableTransformation).getOrThrow();
        // println("DrawableTransformation == : ${wrapped == other.wrapped}")
        // println("DrawableTransformation == : ${wrapped} ---- ${other.wrapped}")
        return wrapped == other.wrapped;
    } else {
        // println("DrawableTransformation != : ${wrapped} ${that}")
        return false
    }
  }

  public operator func !=(that: AnyKey): Bool {
    // println("DrawableTransformation != :")
    if(that is DrawableTransformation) {
        let other: DrawableTransformation = (that as DrawableTransformation).getOrThrow();
        // println("DrawableTransformation != : ${wrapped} ---- ${other.wrapped}")
        return wrapped != other.wrapped;
    } else {
        // println("DrawableTransformation != : true")
        return true
    }
  }

}
