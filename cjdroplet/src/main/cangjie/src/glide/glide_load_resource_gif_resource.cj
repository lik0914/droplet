/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2023-2024. All rights resvered.
 */
 
package glide

public class GifDrawableResource <: GlideResource<GifDrawable> {
  private var gifDrawable: GifDrawable;

  public static func obtain(gifDrawable: GifDrawable): GifDrawableResource {
    return GifDrawableResource(gifDrawable);
  }

  public override func getResourceTypeClass(): ResourceTypeClass {
    return ResourceTypeClass.RESOURCE_TYPE_GIFDRAWABLE
  }

  public override func get(): GifDrawable {
    return gifDrawable;
  }

  public override func getAsAny(): Any {
    return (gifDrawable as Any).getOrThrow()
  }

  public override func getSize(): Int32 {
    return gifDrawable.getSize();
  }

  public override func recycle(): Unit {
    
  }

  public init(gifDrawable: GifDrawable) {
    this.gifDrawable = gifDrawable
  }

  public func toString(): String {
    // TODO GifDrawable toString
      // return this.pixelMap.toString()
      return "GifDrawableResource"
  }

  public func hashCode(): Int64 {
    // TODO GifDrawable hashCode
      // return this.pixelMap.hashCode()
      return 0
  }

  public operator func ==(that: AnyGlideResource): Bool {
    // TODO GifDrawable ==
    if(that is GlideResource<GifDrawable>) {
      return true
    }
    return false
      // return that.get() == this.get()
  }

  public operator func !=(that: AnyGlideResource): Bool {
    // TODO GifDrawable !=
    if(that is GlideResource<GifDrawable>) {
      return false
    }
    return true
      // return that.get() != this.get()
  }

  public func copy(): GlideResource<GifDrawable> {
    return this
  }

}
