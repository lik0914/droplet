package glide.load.resource

import glide.load.*
import glide.util.*
import glide.util.utils.*
import glide.engine.cache.*
import glide.util.exceptions.*
import glide.common.*
from std import fs.*
from ohos import base.*
from std import sync.*
from std import math.*

foreign func malloc(size: UIntNative) : CPointer<Unit>
foreign func free(ptr: CPointer<Unit>): Unit

foreign func setTask(param: UInt32): UInt32
foreign func tfTask(pOut: CPointer<UInt8>, pIn: CPointer<UInt8>, pparam: CPointer<Float32>): UInt32

foreign func getBrightIdx(): UInt32
foreign func getContrastIdx(): UInt32
foreign func getGrayscaleIdx(): UInt32
foreign func getInvertIdx(): UInt32
foreign func getKuwaharaIdx(): UInt32
foreign func getPixelationIdx(): UInt32
foreign func getSepiaIdx(): UInt32
foreign func getSketchIdx(): UInt32
foreign func getSwirlIdx(): UInt32
foreign func getToonIdx(): UInt32
foreign func getVignetteIdx(): UInt32
foreign func getFitcenterIdx(): UInt32
foreign func getCenterinsideIdx(): UInt32
foreign func getCentercropIdx(): UInt32
foreign func getCirclecropIdx(): UInt32
foreign func getRoundedcornersIdx(): UInt32
foreign func getRotateIdx(): UInt32
foreign func getFastBlurIdx(): UInt32
foreign func getIdxNum(): UInt32

public interface TransformationType <: GlideAny<TransformationType> {

}

public class TransformationPixelMap <: TransformationType {

  public var res: PixelMap;

  public init(res: PixelMap) {
    this.res = res
  }

  public func toString(): String {
    // TODO PixelMap
    return ""
      // return this.res.toString()
  }

  public func hashCode(): Int64 {
    // TODO PixelMap
    return 0
      // return this.res.hashCode()
  }

  public operator func ==(that: TransformationType): Bool {
    return true
    // TODO PixelMap
      // return that.get().res == this.get().res
  }

  public operator func !=(that: TransformationType): Bool {
    return false
    // TODO PixelMap
      // return that.get().res != this.get().res
  }
}

public interface AnyTransformation <: AnyKey {
  func transform(resource: AnyGlideResource, outWidth: Int64, outHeight: Int64): AnyGlideResource;
}

public interface Transformation<T> <: AnyTransformation {
    func transform(resource: GlideResource<T>, outWidth: Int64, outHeight: Int64): GlideResource<T>;
}

public open abstract class PixelMapTransformation <: Transformation<PixelMap> {

  public static let SIZE_ORIGINAL: Int64 = -0x7FFFFFFFFFFFFFFF
  //var dataPointer: CPointer<Unit> = CPointer<Unit>()
  //var cdata: CPointer<UInt8> = CPointer<UInt8>()


  let szofParam = 4
  let maxNumParam = 14
  var nParam = 1
  public var puParam = CPointer<Unit>()
  public var pfParam = CPointer<Float32>()

  public func transform(resource: AnyGlideResource, outWidth: Int64, outHeight: Int64): AnyGlideResource {
    if(resource is GlideResource<PixelMap>) {
      let r: GlideResource<PixelMap> = (resource as GlideResource<PixelMap>).getOrThrow()
      return (transform(r, outWidth, outHeight) as AnyGlideResource).getOrThrow()
    } else {
      return resource
    }
  }

  public func transform(resource: GlideResource<PixelMap>, outWidth: Int64, outHeight: Int64): GlideResource<PixelMap> {
    if (!Utils.isValidDimensions(outWidth, outHeight)) {
      throw IllegalArgumentException(
          "Cannot apply transformation on width: ${outWidth} or height: ${outHeight} less than or equal to zero and not Target.SIZE_ORIGINAL");
    }

    var toTransform: PixelMap = resource.get();
    var targetWidth: Int64 = if(outWidth == SIZE_ORIGINAL) {
                                // TODO PixelMap getWidth()
                                // toTransform.getWidth()
                                0
                              } else {
                                outWidth
                              };
    var targetHeight: Int64 = if(outHeight == SIZE_ORIGINAL) {
                                // TODO PixelMap getHeight()
                                // toTransform.height
                                0
                              } else {
                                outHeight
                              };
    var transformed: PixelMap = transform(toTransform, targetWidth, targetHeight);

    var result: GlideResource<PixelMap>;
    // TODO PixelMap equals
    // if (toTransform.equals(transformed)) {
    //   result = resource;
    // } else {
    //   result = PixelMapResource.obtain(transformed);
    // }
    result = PixelMapResource.obtain(transformed);
    return result;
  }

  /**
   * Transforms the given {@link android.graphics.Bitmap} based on the given dimensions and returns
   * the transformed result.
   *
   * <p>The provided Bitmap, toTransform, should not be recycled or returned to the pool. Glide will
   * automatically recycle and/or reuse toTransform if the transformation returns a different
   * Bitmap. Similarly implementations should never recycle or return Bitmaps that are returned as
   * the result of this method. Recycling or returning the provided and/or the returned Bitmap to
   * the pool will lead to a variety of runtime exceptions and drawing errors. See #408 for an
   * example. If the implementation obtains and discards intermediate Bitmaps, they may safely be
   * returned to the BitmapPool and/or recycled.
   *
   * <p>outWidth and outHeight will never be {@link
   * com.bumptech.glide.request.target.Target#SIZE_ORIGINAL}, this class converts them to be the
   * size of the Bitmap we're going to transform before calling this method.
   *
   * @param pool A {@link com.bumptech.glide.load.engine.bitmap_recycle.BitmapPool} that can be used
   *     to obtain and return intermediate {@link Bitmap}s used in this transformation. For every
   *     {@link android.graphics.Bitmap} obtained from the pool during this transformation, a {@link
   *     android.graphics.Bitmap} must also be returned.
   * @param toTransform The {@link android.graphics.Bitmap} to transform.
   * @param outWidth The ideal width of the transformed bitmap (the transformed width does not need
   *     to match exactly).
   * @param outHeight The ideal height of the transformed bitmap (the transformed height does not
   *     need to match exactly).
   */
  protected func transform(toTransform: PixelMap, outWidth: Int64, outHeight: Int64): PixelMap;
}

public class BrightnessFilterTransformation <: PixelMapTransformation {

  private static let ID: String = "com.bumptech.glide.load.resource.bitmap.BrightnessFilterTransformation"
  private static let tfId: UInt32 = unsafe { getBrightIdx() }
  var brightness: Float32

  public init() {
    brightness = 0.0
    nParam = 5
  }

  public init(brightness: Float32) {
    if(brightness <= 0.0) {
      throw GlideException("brightness must be greater than 0.")
    }
    this.brightness = brightness
    nParam = 5
  }

  protected func transform(toTransform: PixelMap, outWidth: Int64, outHeight: Int64): PixelMap {

    //let (ii, arr) = toTransform.readPixelsToBuffer(UInt64(toTransform.getPixelBytesNumber()))
    let arr :Array<UInt8> = Array<UInt8>(Int64(toTransform.getPixelBytesNumber()),item:0)
    toTransform.readPixelsToBuffer(arr)

    var info = toTransform.getImageInfo()
    var w = info.size.width
    var h = info.size.height
    AppLog.error("gl_log BrightnessFilterTransformation : ${brightness}, ${w}, ${h}, ${arr.size}")
    var bitmap = Bitmap(w, h, 4, arr)
    //var bitmap = Bitmap(w, h, 4, Path("/home/yaoy/cj/srcnew/messi480p.bin.bmp"))
    var bitmapOut = Bitmap(w, h, 4)
    bitmapOut.allocCdata()

    puParam = unsafe { malloc(UIntNative(maxNumParam * szofParam)) }
    pfParam = unsafe { CPointer<Float32>(puParam) }
    unsafe { pfParam.write(0, Float32(tfId)) }
    unsafe { pfParam.write(1, Float32(w)) }
    unsafe { pfParam.write(2, Float32(h)) }
    unsafe { pfParam.write(3, Float32(4)) }
    unsafe { pfParam.write(4, brightness) }
    let res = unsafe { tfTask(bitmapOut.cdata, bitmap.cdata, pfParam) }
    bitmapOut.cdataToData()

    for (i in 0..4) {
      AppLog.error("gl_log bright out : ${bitmap.data[i]}, ${bitmapOut.data[i]}, ${brightness}, ${res}")
    }

    let color:Array<UInt8> = Array<UInt8>(bitmapOut.data.size,item:0)
    let px:PixelMap = createPixelMap(color,InitializationOptions(size: info.size, pixelFormat: PixelMapFormat.RGBA_8888, editable: true))

    //var px = PixelMap([UInt32(1)], 1, InitializationOptions(info.size))
    px.writeBufferToPixels(bitmapOut.data)
    bitmap.release()
    bitmapOut.release()
    unsafe { free(puParam) }
    return px
  }

  public func toString(): String {
    //return ID
    return "BrightnessFilterTransformation(brightness=${brightness})";
  }

  public func hashCode(): Int64 {
    //return ID.hashCode()
    Utils.hashCodeWrite(ID, reset: true)
    Utils.hashCodeWrite(brightness)
    return Utils.hashCodeFinish()
  }

  public operator func ==(that: AnyKey): Bool {
    if (that is BrightnessFilterTransformation) {
      var other: BrightnessFilterTransformation = (that as BrightnessFilterTransformation).getOrThrow();
      return brightness == other.brightness
    } else {
      return false
    }
  }

  public operator func !=(that: AnyKey): Bool {
    if(that is BrightnessFilterTransformation) {
      var other: BrightnessFilterTransformation = (that as BrightnessFilterTransformation).getOrThrow();
      return brightness != other.brightness
    } else {
      return true
    }
  }

  public func updateDiskCacheKey(md5: MD5) {
    md5.MD5Update("${ID}${brightness}".toArray())  //update data
  }
}

public class ContrastFilterTransformation <: PixelMapTransformation {

  private static let ID: String = "com.bumptech.glide.load.resource.bitmap.ContrastFilterTransformation"
  private static let tfId: UInt32 = unsafe { getContrastIdx() }
  var contrast: Float32

  public init() {
    contrast = 1.0
    nParam = 5
  }

  public init(contrast: Float32) {
    this.contrast = contrast
    nParam = 5
  }

  protected func transform(toTransform: PixelMap, outWidth: Int64, outHeight: Int64): PixelMap {

    //let (ii, arr) = toTransform.readPixelsToBuffer(UInt64(toTransform.getPixelBytesNumber()))
    let arr :Array<UInt8> = Array<UInt8>(Int64(toTransform.getPixelBytesNumber()),item:0)
    toTransform.readPixelsToBuffer(arr)
    var info = toTransform.getImageInfo()
    var w = info.size.width
    var h = info.size.height
    AppLog.error("gl_log ContrastFilterTransformation : ${contrast}, ${w}, ${h}, ${arr.size}")
    var bitmap = Bitmap(w, h, 4, arr)
    //var bitmap = Bitmap(w, h, 4, Path("/home/yaoy/cj/srcnew/messi480p.bin.bmp"))
    var bitmapOut = Bitmap(w, h, 4)
    bitmapOut.allocCdata()

    puParam = unsafe { malloc(UIntNative(maxNumParam * szofParam)) }
    pfParam = unsafe { CPointer<Float32>(puParam) }
    unsafe { pfParam.write(0, Float32(tfId)) }
    unsafe { pfParam.write(1, Float32(w)) }
    unsafe { pfParam.write(2, Float32(h)) }
    unsafe { pfParam.write(3, Float32(4)) }
    unsafe { pfParam.write(4, contrast) }
    let res = unsafe { tfTask(bitmapOut.cdata, bitmap.cdata, pfParam) }
    bitmapOut.cdataToData()

    for (i in 0..4) {
      AppLog.error("gl_log contrast out : ${bitmap.data[i]}, ${bitmapOut.data[i]}, ${contrast}, ${res}")
    }

     let color:Array<UInt8> = Array<UInt8>(bitmapOut.data.size,item:0)
        let px:PixelMap = createPixelMap(color,InitializationOptions(size: info.size, pixelFormat: PixelMapFormat.RGBA_8888, editable: true))
    //var px = PixelMap([UInt32(1)], 1, InitializationOptions(info.size))
    px.writeBufferToPixels(bitmapOut.data)
    bitmap.release()
    bitmapOut.release()
    unsafe { free(puParam) }
    return px
  }

  public func toString(): String {
    //return ID
    return "ContrastFilterTransformation(contrast=${contrast})";
  }

  public func hashCode(): Int64 {
    //return ID.hashCode()
    Utils.hashCodeWrite(ID, reset: true)
    Utils.hashCodeWrite(contrast)
    return Utils.hashCodeFinish()
  }

  public operator func ==(that: AnyKey): Bool {
    if (that is ContrastFilterTransformation) {
      var other: ContrastFilterTransformation = (that as ContrastFilterTransformation).getOrThrow();
      return contrast == other.contrast
    } else {
      return false
    }
  }

  public operator func !=(that: AnyKey): Bool {
    if(that is ContrastFilterTransformation) {
      var other: ContrastFilterTransformation = (that as ContrastFilterTransformation).getOrThrow();
      return contrast != other.contrast
    } else {
      return true
    }
  }

  public func updateDiskCacheKey(md5: MD5) {
    md5.MD5Update("${ID}${contrast}".toArray())  //update data
  }
}

public class GrayscaleTransformation <: PixelMapTransformation {

  private static let ID: String = "com.bumptech.glide.load.resource.bitmap.GrayscaleTransformation"
  private static let tfId: UInt32 = unsafe { getGrayscaleIdx() }

  public init() {
    nParam = 4
  }

  protected func transform(toTransform: PixelMap, outWidth: Int64, outHeight: Int64): PixelMap {

    //let (ii, arr) = toTransform.readPixelsToBuffer(UInt64(toTransform.getPixelBytesNumber()))
    let arr :Array<UInt8> = Array<UInt8>(Int64(toTransform.getPixelBytesNumber()),item:0)
    toTransform.readPixelsToBuffer(arr)
    var info = toTransform.getImageInfo()
    var w = info.size.width
    var h = info.size.height
    AppLog.error("gl_log GrayscaleTransformation : ${w}, ${h}, ${arr.size}")
    var bitmap = Bitmap(w, h, 4, arr)
    //var bitmap = Bitmap(w, h, 4, Path("/home/yaoy/cj/srcnew/messi480p.bin.bmp"))
    var bitmapOut = Bitmap(w, h, 4)
    bitmapOut.allocCdata()

    puParam = unsafe { malloc(UIntNative(maxNumParam * szofParam)) }
    pfParam = unsafe { CPointer<Float32>(puParam) }
    unsafe { pfParam.write(0, Float32(tfId)) }
    unsafe { pfParam.write(1, Float32(w)) }
    unsafe { pfParam.write(2, Float32(h)) }
    unsafe { pfParam.write(3, Float32(4)) }
    let res = unsafe { tfTask(bitmapOut.cdata, bitmap.cdata, pfParam) }
    bitmapOut.cdataToData()

    for (i in 0..4) {
      AppLog.error("gl_log gray out : ${bitmap.data[i]}, ${bitmapOut.data[i]}, ${res}")
    }

     let color:Array<UInt8> = Array<UInt8>(bitmapOut.data.size,item:0)
        let px:PixelMap = createPixelMap(color,InitializationOptions(size: info.size, pixelFormat: PixelMapFormat.RGBA_8888, editable: true))
    //var px = PixelMap([UInt32(1)], 1, InitializationOptions(info.size))
    px.writeBufferToPixels(bitmapOut.data)
    bitmap.release()
    bitmapOut.release()
    unsafe { free(puParam) }
    return px
  }

  public func toString(): String {
    //return ID
    return "GrayscaleTransformation()";
  }

  public func hashCode(): Int64 {
    //return ID.hashCode()
    Utils.hashCodeWrite(ID, reset: true)
    return Utils.hashCodeFinish()
  }

  public operator func ==(that: AnyKey): Bool {
    return that is GrayscaleTransformation
  }

  public operator func !=(that: AnyKey): Bool {
    return !(that is GrayscaleTransformation)
  }

  public func updateDiskCacheKey(md5: MD5) {
    md5.MD5Update("${ID}".toArray())  //update data
  }
}

public class InvertFilterTransformation <: PixelMapTransformation {

  private static let ID: String = "com.bumptech.glide.load.resource.bitmap.InvertFilterTransformation"
  private static let tfId: UInt32 = unsafe { getInvertIdx() }

  public init() {
    nParam = 4
  }

  protected func transform(toTransform: PixelMap, outWidth: Int64, outHeight: Int64): PixelMap {

    //let (ii, arr) = toTransform.readPixelsToBuffer(UInt64(toTransform.getPixelBytesNumber()))
     let arr :Array<UInt8> = Array<UInt8>(Int64(toTransform.getPixelBytesNumber()),item:0)
     toTransform.readPixelsToBuffer(arr)
    var info = toTransform.getImageInfo()
    var w = info.size.width
    var h = info.size.height
    AppLog.error("gl_log InvertFilterTransformation : ${w}, ${h}, ${arr.size}")
    var bitmap = Bitmap(w, h, 4, arr)
    //var bitmap = Bitmap(w, h, 4, Path("/home/yaoy/cj/srcnew/messi480p.bin.bmp"))
    var bitmapOut = Bitmap(w, h, 4)
    bitmapOut.allocCdata()

    puParam = unsafe { malloc(UIntNative(maxNumParam * szofParam)) }
    pfParam = unsafe { CPointer<Float32>(puParam) }
    unsafe { pfParam.write(0, Float32(tfId)) }
    unsafe { pfParam.write(1, Float32(w)) }
    unsafe { pfParam.write(2, Float32(h)) }
    unsafe { pfParam.write(3, Float32(4)) }
    let res = unsafe { tfTask(bitmapOut.cdata, bitmap.cdata, pfParam) }
    bitmapOut.cdataToData()

    for (i in 0..4) {
      AppLog.error("gl_log gray out : ${bitmap.data[i]}, ${bitmapOut.data[i]}, ${res}")
    }

     let color:Array<UInt8> = Array<UInt8>(bitmapOut.data.size,item:0)
        let px:PixelMap = createPixelMap(color,InitializationOptions(size: info.size, pixelFormat: PixelMapFormat.RGBA_8888, editable: true))
    //var px = PixelMap([UInt32(1)], 1, InitializationOptions(info.size))
    px.writeBufferToPixels(bitmapOut.data)
    bitmap.release()
    bitmapOut.release()
    unsafe { free(puParam) }
    return px
  }

  public func toString(): String {
    //return ID
    return "InvertFilterTransformation()";
  }

  public func hashCode(): Int64 {
    //return ID.hashCode()
    Utils.hashCodeWrite(ID, reset: true)
    return Utils.hashCodeFinish()
  }

  public operator func ==(that: AnyKey): Bool {
    return that is InvertFilterTransformation
  }

  public operator func !=(that: AnyKey): Bool {
    return !(that is InvertFilterTransformation)
  }

  public func updateDiskCacheKey(md5: MD5) {
    md5.MD5Update("${ID}".toArray())  //update data
  }
}

public class KuwaharaFilterTransformation <: PixelMapTransformation {

  private static let ID: String = "com.bumptech.glide.load.resource.bitmap.KuwaharaFilterTransformation"
  private static let tfId: UInt32 = unsafe { getKuwaharaIdx() }
  var radius: Int32

  public init() {
    radius = 25
    nParam = 5
  }

  public init(radius: Int32) {
    this.radius = radius
    nParam = 5
  }

  protected func transform(toTransform: PixelMap, outWidth: Int64, outHeight: Int64): PixelMap {

    //let (ii, arr) = toTransform.readPixelsToBuffer(UInt64(toTransform.getPixelBytesNumber()))
    let arr :Array<UInt8> = Array<UInt8>(Int64(toTransform.getPixelBytesNumber()),item:0)
    toTransform.readPixelsToBuffer(arr)
    var info = toTransform.getImageInfo()
    var w = info.size.width
    var h = info.size.height
    AppLog.error("gl_log KuwaharaFilterTransformation : ${radius}, ${w}, ${h}, ${arr.size}")
    var bitmap = Bitmap(w, h, 4, arr)
    //var bitmap = Bitmap(w, h, 4, Path("/home/yaoy/cj/srcnew/messi480p.bin.bmp"))
    var bitmapOut = Bitmap(w, h, 4)
    bitmapOut.allocCdata()

    puParam = unsafe { malloc(UIntNative(maxNumParam * szofParam)) }
    pfParam = unsafe { CPointer<Float32>(puParam) }
    unsafe { pfParam.write(0, Float32(tfId)) }
    unsafe { pfParam.write(1, Float32(w)) }
    unsafe { pfParam.write(2, Float32(h)) }
    unsafe { pfParam.write(3, Float32(4)) }
    unsafe { pfParam.write(4, Float32(radius)) }
    let res = unsafe { tfTask(bitmapOut.cdata, bitmap.cdata, pfParam) }
    bitmapOut.cdataToData()

    for (i in 0..4) {
      AppLog.error("gl_log contrast out : ${bitmap.data[i]}, ${bitmapOut.data[i]}, ${radius}, ${res}")
    }
    let color:Array<UInt8> = Array<UInt8>(bitmapOut.data.size,item:0)
    let px:PixelMap = createPixelMap(color,InitializationOptions(size: info.size, pixelFormat: PixelMapFormat.RGBA_8888, editable: true))
    //var px = PixelMap([UInt32(1)], 1, InitializationOptions(info.size))
    px.writeBufferToPixels(bitmapOut.data)
    bitmap.release()
    bitmapOut.release()
    unsafe { free(puParam) }
    return px
  }

  public func toString(): String {
    //return ID
    return "KuwaharaFilterTransformation(radius=${radius})";
  }

  public func hashCode(): Int64 {
    //return ID.hashCode()
    Utils.hashCodeWrite(ID, reset: true)
    Utils.hashCodeWrite(Int64(radius))
    return Utils.hashCodeFinish()
  }

  public operator func ==(that: AnyKey): Bool {
    if (that is KuwaharaFilterTransformation) {
      var other: KuwaharaFilterTransformation = (that as KuwaharaFilterTransformation).getOrThrow();
      return radius == other.radius
    } else {
      return false
    }
  }

  public operator func !=(that: AnyKey): Bool {
    if(that is KuwaharaFilterTransformation) {
      var other: KuwaharaFilterTransformation = (that as KuwaharaFilterTransformation).getOrThrow();
      return radius != other.radius
    } else {
      return true
    }
  }

  public func updateDiskCacheKey(md5: MD5) {
    md5.MD5Update("${ID}${radius}".toArray())  //update data
  }
}

public class PixelationFilterTransformation <: PixelMapTransformation {

  private static let ID: String = "com.bumptech.glide.load.resource.bitmap.PixelationFilterTransformation"
  private static let tfId: UInt32 = unsafe { getPixelationIdx() }
  var pixel: Float32
  private var wFactor: Float32 = 0.0
  private var hFactor: Float32 = 0.0

  public init() {
    pixel = 10.0
    nParam = 7
  }

  public init(pixel: Float32) {
    this.pixel = pixel
    nParam = 7
  }

  protected func transform(toTransform: PixelMap, outWidth: Int64, outHeight: Int64): PixelMap {

    //let (ii, arr) = toTransform.readPixelsToBuffer(UInt64(toTransform.getPixelBytesNumber()))
        let arr :Array<UInt8> = Array<UInt8>(Int64(toTransform.getPixelBytesNumber()),item:0)
            toTransform.readPixelsToBuffer(arr)
    var info = toTransform.getImageInfo()
    var w = info.size.width
    var h = info.size.height
    wFactor = 1.0 / Float32(w)
    hFactor = 1.0 / Float32(h)

    AppLog.error("gl_log PixelationFilterTransformation : ${pixel}, ${w}, ${h}, ${arr.size}")
    var bitmap = Bitmap(w, h, 4, arr)
    //var bitmap = Bitmap(w, h, 4, Path("/home/yaoy/cj/srcnew/messi480p.bin.bmp"))
    var bitmapOut = Bitmap(w, h, 4)
    bitmapOut.allocCdata()

    puParam = unsafe { malloc(UIntNative(maxNumParam * szofParam)) }
    pfParam = unsafe { CPointer<Float32>(puParam) }
    unsafe { pfParam.write(0, Float32(tfId)) }
    unsafe { pfParam.write(1, Float32(w)) }
    unsafe { pfParam.write(2, Float32(h)) }
    unsafe { pfParam.write(3, Float32(4)) }
    unsafe { pfParam.write(4, pixel) }
    unsafe { pfParam.write(5, wFactor) }
    unsafe { pfParam.write(6, hFactor) }
    let res = unsafe { tfTask(bitmapOut.cdata, bitmap.cdata, pfParam) }
    bitmapOut.cdataToData()

    for (i in 0..4) {
      AppLog.error("gl_log pix out : ${bitmap.data[i]}, ${bitmapOut.data[i]}, ${pixel}, ${res}")
    }

     let color:Array<UInt8> = Array<UInt8>(bitmapOut.data.size,item:0)
        let px:PixelMap = createPixelMap(color,InitializationOptions(size: info.size, pixelFormat: PixelMapFormat.RGBA_8888, editable: true))
    //var px = PixelMap([UInt32(1)], 1, InitializationOptions(info.size))
    px.writeBufferToPixels(bitmapOut.data)
    bitmap.release()
    bitmapOut.release()
    unsafe { free(puParam) }
    return px
  }

  public func toString(): String {
    //return ID
    return "PixelationFilterTransformation(pixel=${pixel})";
  }

  public func hashCode(): Int64 {
    //return ID.hashCode()
    Utils.hashCodeWrite(ID, reset: true)
    Utils.hashCodeWrite(pixel)
    return Utils.hashCodeFinish()
  }

  public operator func ==(that: AnyKey): Bool {
    if (that is PixelationFilterTransformation) {
      var other: PixelationFilterTransformation = (that as PixelationFilterTransformation).getOrThrow();
      return pixel == other.pixel
    } else {
      return false
    }
  }

  public operator func !=(that: AnyKey): Bool {
    if(that is PixelationFilterTransformation) {
      var other: PixelationFilterTransformation = (that as PixelationFilterTransformation).getOrThrow();
      return pixel != other.pixel
    } else {
      return true
    }
  }

  public func updateDiskCacheKey(md5: MD5) {
    md5.MD5Update("${ID}${pixel}".toArray())  //update data
  }
}

public class SepiaFilterTransformation <: PixelMapTransformation {

  private static let ID: String = "com.bumptech.glide.load.resource.bitmap.SepiaFilterTransformation"
  private static let tfId: UInt32 = unsafe { getSepiaIdx() }
  var intensity: Float32

  public init() {
    intensity = 10.0
    nParam = 5
  }

  public init(intensity: Float32) {
    this.intensity = intensity
    nParam = 5
  }

  protected func transform(toTransform: PixelMap, outWidth: Int64, outHeight: Int64): PixelMap {

    //let (ii, arr) = toTransform.readPixelsToBuffer(UInt64(toTransform.getPixelBytesNumber()))
        let arr :Array<UInt8> = Array<UInt8>(Int64(toTransform.getPixelBytesNumber()),item:0)
            toTransform.readPixelsToBuffer(arr)
    var info = toTransform.getImageInfo()
    var w = info.size.width
    var h = info.size.height

    AppLog.error("gl_log SepiaFilterTransformation : ${intensity}, ${w}, ${h}, ${arr.size}")
    var bitmap = Bitmap(w, h, 4, arr)
    //var bitmap = Bitmap(w, h, 4, Path("/home/yaoy/cj/srcnew/messi480p.bin.bmp"))
    var bitmapOut = Bitmap(w, h, 4)
    bitmapOut.allocCdata()

    puParam = unsafe { malloc(UIntNative(maxNumParam * szofParam)) }
    pfParam = unsafe { CPointer<Float32>(puParam) }
    unsafe { pfParam.write(0, Float32(tfId)) }
    unsafe { pfParam.write(1, Float32(w)) }
    unsafe { pfParam.write(2, Float32(h)) }
    unsafe { pfParam.write(3, Float32(4)) }
    unsafe { pfParam.write(4, intensity) }
    let res = unsafe { tfTask(bitmapOut.cdata, bitmap.cdata, pfParam) }
    bitmapOut.cdataToData()

    for (i in 0..4) {
      AppLog.error("gl_log sepia out : ${bitmap.data[i]}, ${bitmapOut.data[i]}, ${intensity}, ${res}")
    }

    let color:Array<UInt8> = Array<UInt8>(bitmapOut.data.size,item:0)
     let px:PixelMap = createPixelMap(color,InitializationOptions(size: info.size, pixelFormat: PixelMapFormat.RGBA_8888, editable: true))
    //var px = PixelMap([UInt32(1)], 1, InitializationOptions(info.size))
    px.writeBufferToPixels(bitmapOut.data)
    bitmap.release()
    bitmapOut.release()
    unsafe { free(puParam) }
    return px
  }

  public func toString(): String {
    //return ID
    return "SepiaFilterTransformation(intensity=${intensity})";
  }

  public func hashCode(): Int64 {
    //return ID.hashCode()
    Utils.hashCodeWrite(ID, reset: true)
    Utils.hashCodeWrite(intensity)
    return Utils.hashCodeFinish()
  }

  public operator func ==(that: AnyKey): Bool {
    if (that is SepiaFilterTransformation) {
      var other: SepiaFilterTransformation = (that as SepiaFilterTransformation).getOrThrow();
      return intensity == other.intensity
    } else {
      return false
    }
  }

  public operator func !=(that: AnyKey): Bool {
    if(that is SepiaFilterTransformation) {
      var other: SepiaFilterTransformation = (that as SepiaFilterTransformation).getOrThrow();
      return intensity != other.intensity
    } else {
      return true
    }
  }

  public func updateDiskCacheKey(md5: MD5) {
    md5.MD5Update("${ID}${intensity}".toArray())  //update data
  }
}

public class SketchFilterTransformation <: PixelMapTransformation {

  private static let ID: String = "com.bumptech.glide.load.resource.bitmap.SketchFilterTransformation"
  private static let tfId: UInt32 = unsafe { getSketchIdx() }
  private let lineSize: Float32 = 1.0
  private var wTexel: Float32 = 0.0
  private var hTexel: Float32 = 0.0

  public init() {
    nParam = 6
  }

  protected func transform(toTransform: PixelMap, outWidth: Int64, outHeight: Int64): PixelMap {

    //let (ii, arr) = toTransform.readPixelsToBuffer(UInt64(toTransform.getPixelBytesNumber()))
        let arr :Array<UInt8> = Array<UInt8>(Int64(toTransform.getPixelBytesNumber()),item:0)
            toTransform.readPixelsToBuffer(arr)
    var info = toTransform.getImageInfo()
    var w = info.size.width
    var h = info.size.height

    wTexel = lineSize / Float32(w)
    hTexel = lineSize / Float32(h)

    AppLog.error("gl_log SketchFilterTransformation : ${w}, ${h}, ${arr.size}")
    var bitmap = Bitmap(w, h, 4, arr)
    //var bitmap = Bitmap(w, h, 4, Path("/home/yaoy/cj/srcnew/messi480p.bin.bmp"))
    var bitmapOut = Bitmap(w, h, 4)
    bitmapOut.allocCdata()

    puParam = unsafe { malloc(UIntNative(maxNumParam * szofParam)) }
    pfParam = unsafe { CPointer<Float32>(puParam) }
    unsafe { pfParam.write(0, Float32(tfId)) }
    unsafe { pfParam.write(1, Float32(w)) }
    unsafe { pfParam.write(2, Float32(h)) }
    unsafe { pfParam.write(3, Float32(4)) }
    unsafe { pfParam.write(4, wTexel) }
    unsafe { pfParam.write(5, hTexel) }
    let res = unsafe { tfTask(bitmapOut.cdata, bitmap.cdata, pfParam) }
    bitmapOut.cdataToData()

    for (i in 0..4) {
      AppLog.error("gl_log sketch out : ${bitmap.data[i]}, ${bitmapOut.data[i]}, ${res}")
    }

     let color:Array<UInt8> = Array<UInt8>(bitmapOut.data.size,item:0)
    let px:PixelMap = createPixelMap(color,InitializationOptions(size: info.size, pixelFormat: PixelMapFormat.RGBA_8888, editable: true))
    //var px = PixelMap([UInt32(1)], 1, InitializationOptions(info.size))
    px.writeBufferToPixels(bitmapOut.data)
    bitmap.release()
    bitmapOut.release()
    unsafe { free(puParam) }
    return px
  }

  public func toString(): String {
    //return ID
    return "SketchFilterTransformation()";
  }

  public func hashCode(): Int64 {
    //return ID.hashCode()
    Utils.hashCodeWrite(ID, reset: true)
    return Utils.hashCodeFinish()
  }

  public operator func ==(that: AnyKey): Bool {
    return (that is SketchFilterTransformation)
  }

  public operator func !=(that: AnyKey): Bool {
    return !(that is SketchFilterTransformation)
  }

  public func updateDiskCacheKey(md5: MD5) {
    md5.MD5Update("${ID}".toArray())  //update data
  }
}

public class SwirlFilterTransformation <: PixelMapTransformation {

  private static let ID: String = "com.bumptech.glide.load.resource.bitmap.SwirlFilterTransformation"
  private static let tfId: UInt32 = unsafe { getSwirlIdx() }
  private var radius: Float32 = 0.5
  private var angle: Float32 = 1.0
  private var xCenter: Float32 = 0.5
  private var yCenter: Float32 = 0.5

  public init() {
    nParam = 8
  }

  public init(radius: Float32, angle: Float32, x: Float32, y: Float32) {
    this.radius = radius
    this.angle = angle
    this.xCenter = x
    this.yCenter = y
    nParam = 8
  }

  protected func transform(toTransform: PixelMap, outWidth: Int64, outHeight: Int64): PixelMap {

    //let (ii, arr) = toTransform.readPixelsToBuffer(UInt64(toTransform.getPixelBytesNumber()))
        let arr :Array<UInt8> = Array<UInt8>(Int64(toTransform.getPixelBytesNumber()),item:0)
            toTransform.readPixelsToBuffer(arr)
    var info = toTransform.getImageInfo()
    var w = info.size.width
    var h = info.size.height

    AppLog.error("gl_log SwirlFilterTransformation : ${w}, ${h}, ${arr.size}")
    var bitmap = Bitmap(w, h, 4, arr)
    //var bitmap = Bitmap(w, h, 4, Path("/home/yaoy/cj/srcnew/messi480p.bin.bmp"))
    var bitmapOut = Bitmap(w, h, 4)
    bitmapOut.allocCdata()

    puParam = unsafe { malloc(UIntNative(maxNumParam * szofParam)) }
    pfParam = unsafe { CPointer<Float32>(puParam) }
    unsafe { pfParam.write(0, Float32(tfId)) }
    unsafe { pfParam.write(1, Float32(w)) }
    unsafe { pfParam.write(2, Float32(h)) }
    unsafe { pfParam.write(3, Float32(4)) }
    unsafe { pfParam.write(4, radius) }
    unsafe { pfParam.write(5, angle) }
    unsafe { pfParam.write(6, xCenter) }
    unsafe { pfParam.write(7, yCenter) }
    let res = unsafe { tfTask(bitmapOut.cdata, bitmap.cdata, pfParam) }
    bitmapOut.cdataToData()

    for (i in 0..4) {
      AppLog.error("gl_log swirl out : ${bitmap.data[i]}, ${bitmapOut.data[i]}, ${res}")
    }

     let color:Array<UInt8> = Array<UInt8>(bitmapOut.data.size,item:0)
        let px:PixelMap = createPixelMap(color,InitializationOptions(size: info.size, pixelFormat: PixelMapFormat.RGBA_8888, editable: true))
    //var px = PixelMap([UInt32(1)], 1, InitializationOptions(info.size))
    px.writeBufferToPixels(bitmapOut.data)
    bitmap.release()
    bitmapOut.release()
    unsafe { free(puParam) }
    return px
  }

  public func toString(): String {
    //return ID
    return "SwirlFilterTransformation(radius=${radius},angle=${angle},center=(${xCenter},${yCenter}))";
  }

  public func hashCode(): Int64 {
    //return ID.hashCode()
    Utils.hashCodeWrite(ID, reset: true)
    Utils.hashCodeWrite(radius)
    Utils.hashCodeWrite(angle)
    Utils.hashCodeWrite(xCenter)
    Utils.hashCodeWrite(yCenter)
    return Utils.hashCodeFinish()
  }

  public operator func ==(that: AnyKey): Bool {
    if (that is SwirlFilterTransformation) {
      var other: SwirlFilterTransformation = (that as SwirlFilterTransformation).getOrThrow();
      return ((radius == other.radius) && (angle == other.angle) && (xCenter == other.xCenter) && (yCenter == other.yCenter))
    } else {
      return false
    }
  }

  public operator func !=(that: AnyKey): Bool {
    if (that is SwirlFilterTransformation) {
      var other: SwirlFilterTransformation = (that as SwirlFilterTransformation).getOrThrow();
      return !((radius == other.radius) && (angle == other.angle) && (xCenter == other.xCenter) && (yCenter == other.yCenter))
    } else {
      return true
    }
  }

  public func updateDiskCacheKey(md5: MD5) {
    md5.MD5Update("${ID}${radius}${angle}${xCenter}${yCenter}".toArray())  //update data
  }
}

public class ToonFilterTransformation <: PixelMapTransformation {

  private static let ID: String = "com.bumptech.glide.load.resource.bitmap.ToonFilterTransformation"
  private static let tfId: UInt32 = unsafe { getToonIdx() }
  private let lineSize: Float32 = 1.0
  private var wTexel: Float32 = 0.0
  private var hTexel: Float32 = 0.0

  private var threshold: Float32 = 0.2
  private var quantizationLevels: Float32 = 10.0

  public init() {
    nParam = 8
  }

  public init(threshold: Float32, quantizationLevels: Float32) {
    this.threshold = threshold
    this.quantizationLevels = quantizationLevels
    nParam = 8
  }

  protected func transform(toTransform: PixelMap, outWidth: Int64, outHeight: Int64): PixelMap {

    //let (ii, arr) = toTransform.readPixelsToBuffer(UInt64(toTransform.getPixelBytesNumber()))
        let arr :Array<UInt8> = Array<UInt8>(Int64(toTransform.getPixelBytesNumber()),item:0)
            toTransform.readPixelsToBuffer(arr)
    var info = toTransform.getImageInfo()
    var w = info.size.width
    var h = info.size.height

    wTexel = lineSize / Float32(w)
    hTexel = lineSize / Float32(h)

    AppLog.error("gl_log ToonFilterTransformation : ${w}, ${h}, ${arr.size}")
    var bitmap = Bitmap(w, h, 4, arr)
    //var bitmap = Bitmap(w, h, 4, Path("/home/yaoy/cj/srcnew/messi480p.bin.bmp"))
    var bitmapOut = Bitmap(w, h, 4)
    bitmapOut.allocCdata()

    puParam = unsafe { malloc(UIntNative(maxNumParam * szofParam)) }
    pfParam = unsafe { CPointer<Float32>(puParam) }
    unsafe { pfParam.write(0, Float32(tfId)) }
    unsafe { pfParam.write(1, Float32(w)) }
    unsafe { pfParam.write(2, Float32(h)) }
    unsafe { pfParam.write(3, Float32(4)) }
    unsafe { pfParam.write(4, wTexel) }
    unsafe { pfParam.write(5, hTexel) }
    unsafe { pfParam.write(6, threshold) }
    unsafe { pfParam.write(7, quantizationLevels) }
    let res = unsafe { tfTask(bitmapOut.cdata, bitmap.cdata, pfParam) }
    bitmapOut.cdataToData()

    for (i in 0..4) {
      AppLog.error("gl_log toon out : ${bitmap.data[i]}, ${bitmapOut.data[i]}, ${res}")
    }

     let color:Array<UInt8> = Array<UInt8>(bitmapOut.data.size,item:0)
        let px:PixelMap = createPixelMap(color,InitializationOptions(size: info.size, pixelFormat: PixelMapFormat.RGBA_8888, editable: true))
    //var px = PixelMap([UInt32(1)], 1, InitializationOptions(info.size))
    px.writeBufferToPixels(bitmapOut.data)
    bitmap.release()
    bitmapOut.release()
    unsafe { free(puParam) }
    return px
  }

  public func toString(): String {
    //return ID
    return "ToonFilterTransformation(threshold=${threshold},quantizationLevels=${quantizationLevels})";
  }

  public func hashCode(): Int64 {
    //return ID.hashCode()
    Utils.hashCodeWrite(ID, reset: true)
    Utils.hashCodeWrite(threshold)
    Utils.hashCodeWrite(quantizationLevels)
    return Utils.hashCodeFinish()
  }

  public operator func ==(that: AnyKey): Bool {
    if (that is ToonFilterTransformation) {
      var other: ToonFilterTransformation = (that as ToonFilterTransformation).getOrThrow();
      return ((threshold == other.threshold) && (quantizationLevels == other.quantizationLevels))
    } else {
      return false
    }
  }

  public operator func !=(that: AnyKey): Bool {
    if (that is ToonFilterTransformation) {
      var other: ToonFilterTransformation = (that as ToonFilterTransformation).getOrThrow();
      return !((threshold == other.threshold) && (quantizationLevels == other.quantizationLevels))
    } else {
      return true
    }
  }

  public func updateDiskCacheKey(md5: MD5) {
    md5.MD5Update("${ID}${threshold}${quantizationLevels}".toArray())  //update data
  }
}


public class VignetteFilterTransformation <: PixelMapTransformation {

  private static let ID: String = "com.bumptech.glide.load.resource.bitmap.VignetteFilterTransformation"
  private static let tfId: UInt32 = unsafe { getVignetteIdx() }
  private var xCenter: Float32 = 0.5
  private var yCenter: Float32 = 0.5
  private var rVnt: Float32 = 0.0
  private var gVnt: Float32 = 0.0
  private var bVnt: Float32 = 0.0
  private var startVnt: Float32 = 0.0
  private var endVnt: Float32 = 0.75

  public init() {
    nParam = 11
  }

  public init(x: Float32, y: Float32, r: Float32, g: Float32, b: Float32, start: Float32, end: Float32) {
    this.xCenter = x
    this.yCenter = y
    this.rVnt = r
    this.gVnt = g
    this.bVnt = b
    this.startVnt = start
    this.endVnt = end
    nParam = 11
  }

  protected func transform(toTransform: PixelMap, outWidth: Int64, outHeight: Int64): PixelMap {

    //let (ii, arr) = toTransform.readPixelsToBuffer(UInt64(toTransform.getPixelBytesNumber()))
        let arr :Array<UInt8> = Array<UInt8>(Int64(toTransform.getPixelBytesNumber()),item:0)
            toTransform.readPixelsToBuffer(arr)
    var info = toTransform.getImageInfo()
    var w = info.size.width
    var h = info.size.height

    AppLog.error("gl_log VignetteFilterTransformation : ${w}, ${h}, ${arr.size}")
    var bitmap = Bitmap(w, h, 4, arr)
    //var bitmap = Bitmap(w, h, 4, Path("/home/yaoy/cj/srcnew/messi480p.bin.bmp"))
    var bitmapOut = Bitmap(w, h, 4)
    bitmapOut.allocCdata()

    puParam = unsafe { malloc(UIntNative(maxNumParam * szofParam)) }
    pfParam = unsafe { CPointer<Float32>(puParam) }
    unsafe { pfParam.write(0, Float32(tfId)) }
    unsafe { pfParam.write(1, Float32(w)) }
    unsafe { pfParam.write(2, Float32(h)) }
    unsafe { pfParam.write(3, Float32(4)) }
    unsafe { pfParam.write(4, xCenter) }
    unsafe { pfParam.write(5, yCenter) }
    unsafe { pfParam.write(6, rVnt) }
    unsafe { pfParam.write(7, gVnt) }
    unsafe { pfParam.write(8, bVnt) }
    unsafe { pfParam.write(9, startVnt) }
    unsafe { pfParam.write(10, endVnt) }
    let res = unsafe { tfTask(bitmapOut.cdata, bitmap.cdata, pfParam) }
    bitmapOut.cdataToData()

    for (i in 0..4) {
      AppLog.error("gl_log vignette out : ${bitmap.data[i]}, ${bitmapOut.data[i]}, ${res}")
    }

     let color:Array<UInt8> = Array<UInt8>(bitmapOut.data.size,item:0)
    let px:PixelMap = createPixelMap(color,InitializationOptions(size: info.size, pixelFormat: PixelMapFormat.RGBA_8888, editable: true))
    //var px = PixelMap([UInt32(1)], 1, InitializationOptions(info.size))
    px.writeBufferToPixels(bitmapOut.data)
    bitmap.release()
    bitmapOut.release()
    unsafe { free(puParam) }
    return px
  }

  public func toString(): String {
    //return ID
    return "VignetteFilterTransformation(center=(${xCenter},${yCenter}),color=(${rVnt},${gVnt},${bVnt}),range=(${startVnt},${endVnt}))";
  }

  public func hashCode(): Int64 {
    //return ID.hashCode()
    Utils.hashCodeWrite(ID, reset: true)
    Utils.hashCodeWrite(xCenter)
    Utils.hashCodeWrite(yCenter)
    Utils.hashCodeWrite(rVnt)
    Utils.hashCodeWrite(gVnt)
    Utils.hashCodeWrite(bVnt)
    Utils.hashCodeWrite(startVnt)
    Utils.hashCodeWrite(endVnt)
    return Utils.hashCodeFinish()
  }

  public operator func ==(that: AnyKey): Bool {
    if (that is VignetteFilterTransformation) {
      var other: VignetteFilterTransformation = (that as VignetteFilterTransformation).getOrThrow();
      return ((xCenter == other.xCenter) &&
              (yCenter == other.yCenter) &&
              (rVnt == other.rVnt) &&
              (gVnt == other.gVnt) &&
              (bVnt == other.bVnt) &&
              (startVnt == other.startVnt) &&
              (endVnt == other.endVnt))
    } else {
      return false
    }
  }

  public operator func !=(that: AnyKey): Bool {
    if (that is VignetteFilterTransformation) {
      var other: VignetteFilterTransformation = (that as VignetteFilterTransformation).getOrThrow();
      return !((xCenter == other.xCenter) &&
               (yCenter == other.yCenter) &&
               (rVnt == other.rVnt) &&
               (gVnt == other.gVnt) &&
               (bVnt == other.bVnt) &&
               (startVnt == other.startVnt) &&
               (endVnt == other.endVnt))
    } else {
      return true
    }
  }

  public func updateDiskCacheKey(md5: MD5) {
    md5.MD5Update("${ID}${xCenter}${yCenter}${rVnt}${gVnt}${bVnt}${startVnt}${endVnt}".toArray())  //update data
  }
}
////////////////////////////////////////////////////////
public class Rotate <: PixelMapTransformation {

  private static let ID: String = "com.bumptech.glide.load.resource.bitmap.Rotate"
  private static let tfId: UInt32 = unsafe { getRotateIdx() }
  var degree: Float32
  var wi: Int32 = 0
  var hi: Int32 = 0
  var wo: Int32 = 0
  var ho: Int32 = 0
  public var vx: Array<Float32> = [-1.0, 1.0, -1.0, 1.0]
  public var vy: Array<Float32> = [-1.0, -1.0, 1.0, 1.0]
  let pi: Float32 = 3.1416926

  public init(degree: Float32) {
    this.degree = degree
    nParam = 5
  }

  private func updateParams() {
    var w1 = Float32(wi) / 2.0
    var h1 = Float32(hi) / 2.0
    vx = Array<Float32>([-w1, w1, -w1, w1])
    vy = Array<Float32>([-h1, -h1, h1, h1])
    let rad = -degree / 180.0 * pi
    let c: Float32 = cos(rad)
    let s: Float32 = sin(rad)

    for (i in 0..4) {
      var x = vx[i]
      var y = vy[i]
      vx[i] = c * x - s * y
      vy[i] = s * x + c * y
    }

    var xmin = min(min(vx[0], vx[1]), min(vx[2], vx[3]))
    var ymin = min(min(vy[0], vy[1]), min(vy[2], vy[3]))
    var xmax = max(max(vx[0], vx[1]), max(vx[2], vx[3]))
    var ymax = max(max(vy[0], vy[1]), max(vy[2], vy[3]))

    wo = Int32(round(xmax - xmin))
    ho = Int32(round(ymax - ymin))

    var w2 = (xmax - xmin) / 2.0
    var h2 = (ymax - ymin) / 2.0
    for (i in 0..4) {
      vx[i] = vx[i] / w2
      vy[i] = vy[i] / h2
    }
  }

  protected func transform(toTransform: PixelMap, outWidth: Int64, outHeight: Int64): PixelMap {

    //let (ii, arr) = toTransform.readPixelsToBuffer(UInt64(toTransform.getPixelBytesNumber()))
        let arr :Array<UInt8> = Array<UInt8>(Int64(toTransform.getPixelBytesNumber()),item:0)
            toTransform.readPixelsToBuffer(arr)
    var info = toTransform.getImageInfo()
    var w = info.size.width
    var h = info.size.height
    var bitmap = Bitmap(w, h, 4, arr)
    //var bitmap = Bitmap(w, h, 4, Path("/home/yaoy/cj/srcnew/messi480p.bin.bmp"))

    wi = Int32(w)
    hi = Int32(h)
    updateParams()
    puParam = unsafe { malloc(UIntNative(maxNumParam * szofParam)) }
    pfParam = unsafe { CPointer<Float32>(puParam) }
    unsafe { pfParam.write(0, Float32(tfId)) }
    unsafe { pfParam.write(1, Float32(w)) }
    unsafe { pfParam.write(2, Float32(h)) }
    unsafe { pfParam.write(3, Float32(4)) }
    unsafe { pfParam.write(4, Float32(wo)) }
    unsafe { pfParam.write(5, Float32(ho)) }
    unsafe { pfParam.write(6, vx[0]) }
    unsafe { pfParam.write(7, vx[1]) }
    unsafe { pfParam.write(8, vx[2]) }
    unsafe { pfParam.write(9, vx[3]) }
    unsafe { pfParam.write(10, vy[0]) }
    unsafe { pfParam.write(11, vy[1]) }
    unsafe { pfParam.write(12, vy[2]) }
    unsafe { pfParam.write(13, vy[3]) }

    var bitmapOut = Bitmap(wo, ho, 4)
    bitmapOut.allocCdata()
    AppLog.error("gl_log Rotate : ${degree}, ${w}, ${h}, ${wo}, ${ho}, ${arr.size}")
    let res = unsafe { tfTask(bitmapOut.cdata, bitmap.cdata, pfParam) }
    bitmapOut.cdataToData()

    for (i in 0..4) {
      AppLog.error("gl_log rotate out : ${bitmap.data[i]}, ${bitmapOut.data[i]}, ${degree}, ${res}")
    }

     let color:Array<UInt8> = Array<UInt8>(bitmapOut.data.size,item:0)
        let px:PixelMap = createPixelMap(color,InitializationOptions(size: Size(width: wo, height: ho), pixelFormat: PixelMapFormat.RGBA_8888, editable: true))
    //var px = PixelMap([UInt32(1)], 1, InitializationOptions(Size(width: wo, height: ho)))
    px.writeBufferToPixels(bitmapOut.data)
    bitmap.release()
    bitmapOut.release()
    unsafe { free(puParam) }
    return px
  }

  public func toString(): String {
    //return ID
    return "Rotate(degree=${degree})";
  }

  public func hashCode(): Int64 {
    //return ID.hashCode()
    Utils.hashCodeWrite(ID, reset: true)
    Utils.hashCodeWrite(degree)
    return Utils.hashCodeFinish()
  }

  public operator func ==(that: AnyKey): Bool {
    if (that is Rotate) {
      var other: Rotate = (that as Rotate).getOrThrow();
      return degree == other.degree
    } else {
      return false
    }
  }

  public operator func !=(that: AnyKey): Bool {
    if(that is Rotate) {
      var other: Rotate = (that as Rotate).getOrThrow();
      return degree != other.degree
    } else {
      return true
    }
  }

  public func updateDiskCacheKey(md5: MD5) {
    md5.MD5Update("${ID}${degree}".toArray())  //update data
  }
}

public class CenterCrop <: PixelMapTransformation {

  private static let ID: String = "com.bumptech.glide.load.resource.bitmap.CenterCrop"
  private static let tfId: UInt32 = unsafe { getCentercropIdx() }

  public init() {
    nParam = 8
  }

  protected func transform(toTransform: PixelMap, outWidth: Int64, outHeight: Int64): PixelMap {

    //let (ii, arr) = toTransform.readPixelsToBuffer(UInt64(toTransform.getPixelBytesNumber()))
        let arr :Array<UInt8> = Array<UInt8>(Int64(toTransform.getPixelBytesNumber()),item:0)
            toTransform.readPixelsToBuffer(arr)
    var info = toTransform.getImageInfo()
    var w = info.size.width
    var h = info.size.height
    var wo = Int32(outWidth)
    var ho = Int32(outHeight)
    AppLog.error("gl_log CenterCrop : ${w}, ${h}, ${wo}, ${ho}, ${arr.size}")
    var bitmap = Bitmap(w, h, 4, arr)
    //var bitmap = Bitmap(w, h, 4, Path("/home/yaoy/cj/srcnew/messi480p.bin.bmp"))

    if (w == wo && h == ho) {
      return toTransform
    }

    var scale: Float32 = 0.0
    var dx: Float32 = 1.0
    var dy: Float32 = 1.0
    if (Int64(w) * Int64(ho) > Int64(wo) * Int64(h))
    {
      scale = Float32(ho) / Float32(h);
      dx = abs(Float32(wo) - Float32(w) * scale) / Float32(wo) + 1.0;
    }
    else
    {
      scale = Float32(wo) / Float32(w);
      dy = abs(Float32(ho) - Float32(h) * scale) / Float32(ho) + 1.0;
    }

    puParam = unsafe { malloc(UIntNative(maxNumParam * szofParam)) }
    pfParam = unsafe { CPointer<Float32>(puParam) }
    unsafe { pfParam.write(0, Float32(tfId)) }
    unsafe { pfParam.write(1, Float32(w)) }
    unsafe { pfParam.write(2, Float32(h)) }
    unsafe { pfParam.write(3, Float32(4)) }
    unsafe { pfParam.write(4, Float32(dx)) }
    unsafe { pfParam.write(5, Float32(dy)) }
    unsafe { pfParam.write(6, Float32(wo)) }
    unsafe { pfParam.write(7, Float32(ho)) }

    var bitmapOut = Bitmap(wo, ho, 4)
    bitmapOut.allocCdata()
    let res = unsafe { tfTask(bitmapOut.cdata, bitmap.cdata, pfParam) }
    bitmapOut.cdataToData()

    for (i in 0..4) {
      AppLog.error("gl_log CenterCrop out : ${bitmap.data[i]}, ${bitmapOut.data[i]}, ${res}")
    }

     let color:Array<UInt8> = Array<UInt8>(bitmapOut.data.size,item:0)
     let px:PixelMap = createPixelMap(color,InitializationOptions(size: Size(width: wo, height: ho), pixelFormat: PixelMapFormat.RGBA_8888, editable: true))
    //var px = PixelMap([UInt32(1)], 1, InitializationOptions(Size(width: wo, height: ho)))

    px.writeBufferToPixels(bitmapOut.data)
    bitmap.release()
    bitmapOut.release()
    unsafe { free(puParam) }
    return px
  }

  public func toString(): String {
    //return ID
    return "CenterCrop()";
  }

  public func hashCode(): Int64 {
    //return ID.hashCode()
    Utils.hashCodeWrite(ID, reset: true)
    return Utils.hashCodeFinish()
  }

  public operator func ==(that: AnyKey): Bool {
    if (that is CenterCrop) {
      return true
    } else {
      return false
    }
  }

  public operator func !=(that: AnyKey): Bool {
    if(that is CenterCrop) {
      return false
    } else {
      return true
    }
  }

  public func updateDiskCacheKey(md5: MD5) {
    md5.MD5Update("${ID}".toArray())  //update data
  }
}

public class CenterInside <: PixelMapTransformation {

  private static let ID: String = "com.bumptech.glide.load.resource.bitmap.CenterInside"
  private static let tfId: UInt32 = unsafe { getCenterinsideIdx() }

  public init() {
    nParam = 6
  }

  protected func transform(toTransform: PixelMap, outWidth: Int64, outHeight: Int64): PixelMap {

    //let (ii, arr) = toTransform.readPixelsToBuffer(UInt64(toTransform.getPixelBytesNumber()))
        let arr :Array<UInt8> = Array<UInt8>(Int64(toTransform.getPixelBytesNumber()),item:0)
            toTransform.readPixelsToBuffer(arr)
    var info = toTransform.getImageInfo()
    var w = info.size.width
    var h = info.size.height
    var wo = Int32(outWidth)
    var ho = Int32(outHeight)
    AppLog.error("gl_log CenterInside : ${w}, ${h}, ${wo}, ${ho}, ${arr.size}")
    var bitmap = Bitmap(w, h, 4, arr)
    //var bitmap = Bitmap(w, h, 4, Path("/home/yaoy/cj/srcnew/messi480p.bin.bmp"))

    if (w <= wo && h <= ho) {
      return toTransform
    }

    var wr = Float32(wo) / Float32(w)
    var hr = Float32(ho) / Float32(h)
    var minr = min(wr, hr)
    wo = Int32(round(minr * Float32(w)))
    ho = Int32(round(minr * Float32(h)))

    puParam = unsafe { malloc(UIntNative(maxNumParam * szofParam)) }
    pfParam = unsafe { CPointer<Float32>(puParam) }
    unsafe { pfParam.write(0, Float32(tfId)) }
    unsafe { pfParam.write(1, Float32(w)) }
    unsafe { pfParam.write(2, Float32(h)) }
    unsafe { pfParam.write(3, Float32(4)) }
    unsafe { pfParam.write(4, Float32(wo)) }
    unsafe { pfParam.write(5, Float32(ho)) }

    var bitmapOut = Bitmap(wo, ho, 4)
    bitmapOut.allocCdata()
    let res = unsafe { tfTask(bitmapOut.cdata, bitmap.cdata, pfParam) }
    bitmapOut.cdataToData()

    for (i in 0..4) {
      AppLog.error("gl_log CenterInside out : ${bitmap.data[i]}, ${bitmapOut.data[i]}, ${res}")
    }

     let color:Array<UInt8> = Array<UInt8>(bitmapOut.data.size,item:0)
     let px:PixelMap = createPixelMap(color,InitializationOptions(size: Size(width: wo, height: ho), pixelFormat: PixelMapFormat.RGBA_8888, editable: true))
    //var px = PixelMap([UInt32(1)], 1, InitializationOptions(Size(width: wo, height: ho)))

    px.writeBufferToPixels(bitmapOut.data)
    bitmap.release()
    bitmapOut.release()
    unsafe { free(puParam) }
    return px
  }

  public func toString(): String {
    //return ID
    return "CenterInside()";
  }

  public func hashCode(): Int64 {
    //return ID.hashCode()
    Utils.hashCodeWrite(ID, reset: true)
    return Utils.hashCodeFinish()
  }

  public operator func ==(that: AnyKey): Bool {
    if (that is CenterInside) {
      return true
    } else {
      return false
    }
  }

  public operator func !=(that: AnyKey): Bool {
    if(that is CenterInside) {
      return false
    } else {
      return true
    }
  }

  public func updateDiskCacheKey(md5: MD5) {
    md5.MD5Update("${ID}".toArray())  //update data
  }
}

public class FitCenter <: PixelMapTransformation {

  private static let ID: String = "com.bumptech.glide.load.resource.bitmap.FitCenter"
  private static let tfId: UInt32 = unsafe { getFitcenterIdx() }

  public init() {
    nParam = 6
  }

  protected func transform(toTransform: PixelMap, outWidth: Int64, outHeight: Int64): PixelMap {

    //let (ii, arr) = toTransform.readPixelsToBuffer(UInt64(toTransform.getPixelBytesNumber()))
        let arr :Array<UInt8> = Array<UInt8>(Int64(toTransform.getPixelBytesNumber()),item:0)
            toTransform.readPixelsToBuffer(arr)
    var info = toTransform.getImageInfo()
    var w = info.size.width
    var h = info.size.height
    var wo = Int32(outWidth)
    var ho = Int32(outHeight)
    AppLog.error("gl_log FitCenter : ${w}, ${h}, ${wo}, ${ho}, ${arr.size}")
    var bitmap = Bitmap(w, h, 4, arr)
    //var bitmap = Bitmap(w, h, 4, Path("/home/yaoy/cj/srcnew/messi480p.bin.bmp"))

    if (w == wo && h == ho) {
      return toTransform
    }

    var wr = Float32(wo) / Float32(w)
    var hr = Float32(ho) / Float32(h)
    var minr = min(wr, hr)
    wo = Int32(round(minr * Float32(w)))
    ho = Int32(round(minr * Float32(h)))

    puParam = unsafe { malloc(UIntNative(maxNumParam * szofParam)) }
    pfParam = unsafe { CPointer<Float32>(puParam) }
    unsafe { pfParam.write(0, Float32(tfId)) }
    unsafe { pfParam.write(1, Float32(w)) }
    unsafe { pfParam.write(2, Float32(h)) }
    unsafe { pfParam.write(3, Float32(4)) }
    unsafe { pfParam.write(4, Float32(wo)) }
    unsafe { pfParam.write(5, Float32(ho)) }

    var bitmapOut = Bitmap(wo, ho, 4)
    bitmapOut.allocCdata()
    let res = unsafe { tfTask(bitmapOut.cdata, bitmap.cdata, pfParam) }
    bitmapOut.cdataToData()

    for (i in 0..4) {
      AppLog.error("gl_log FitCenter out : ${bitmap.data[i]}, ${bitmapOut.data[i]}, ${res}")
    }

     let color:Array<UInt8> = Array<UInt8>(bitmapOut.data.size,item:0)
     let px:PixelMap = createPixelMap(color,InitializationOptions(size: Size(width: wo, height: ho), pixelFormat: PixelMapFormat.RGBA_8888, editable: true))
    //var px = PixelMap([UInt32(1)], 1, InitializationOptions(Size(width: wo, height: ho)))

    px.writeBufferToPixels(bitmapOut.data)
    bitmap.release()
    bitmapOut.release()
    unsafe { free(puParam) }
    return px
  }

  public func toString(): String {
    //return ID
    return "FitCenter()";
  }

  public func hashCode(): Int64 {
    //return ID.hashCode()
    Utils.hashCodeWrite(ID, reset: true)
    return Utils.hashCodeFinish()
  }

  public operator func ==(that: AnyKey): Bool {
    if (that is FitCenter) {
      return true
    } else {
      return false
    }
  }

  public operator func !=(that: AnyKey): Bool {
    if(that is FitCenter) {
      return false
    } else {
      return true
    }
  }

  public func updateDiskCacheKey(md5: MD5) {
    md5.MD5Update("${ID}".toArray())  //update data
  }
}

public class CircleCrop <: PixelMapTransformation {

  private static let ID: String = "com.bumptech.glide.load.resource.bitmap.CircleCrop"
  private static let tfId: UInt32 = unsafe { getCirclecropIdx() }

  public init() {
    nParam = 8
  }

  protected func transform(toTransform: PixelMap, outWidth: Int64, outHeight: Int64): PixelMap {

    //let (ii, arr) = toTransform.readPixelsToBuffer(UInt64(toTransform.getPixelBytesNumber()))
        let arr :Array<UInt8> = Array<UInt8>(Int64(toTransform.getPixelBytesNumber()),item:0)
            toTransform.readPixelsToBuffer(arr)
    var info = toTransform.getImageInfo()
    var w = info.size.width
    var h = info.size.height
    var edge = Int32(min(outWidth, outHeight))
    var wo = edge
    var ho = edge
    AppLog.error("gl_log CircleCrop : ${w}, ${h}, ${wo}, ${ho}, ${arr.size}")
    var bitmap = Bitmap(w, h, 4, arr)
    //var bitmap = Bitmap(w, h, 4, Path("/home/yaoy/cj/srcnew/messi480p.bin.bmp"))


    var scale: Float32 = 0.0
    var dx: Float32 = 1.0
    var dy: Float32 = 1.0
    if (Int64(w) * Int64(ho) > Int64(wo) * Int64(h))
    {
      scale = Float32(ho) / Float32(h);
      dx = abs(Float32(wo) - Float32(w) * scale) / Float32(wo) + 1.0;
    }
    else
    {
      scale = Float32(wo) / Float32(w);
      dy = abs(Float32(ho) - Float32(h) * scale) / Float32(ho) + 1.0;
    }

    puParam = unsafe { malloc(UIntNative(maxNumParam * szofParam)) }
    pfParam = unsafe { CPointer<Float32>(puParam) }
    unsafe { pfParam.write(0, Float32(tfId)) }
    unsafe { pfParam.write(1, Float32(w)) }
    unsafe { pfParam.write(2, Float32(h)) }
    unsafe { pfParam.write(3, Float32(4)) }
    unsafe { pfParam.write(4, Float32(dx)) }
    unsafe { pfParam.write(5, Float32(dy)) }
    unsafe { pfParam.write(6, Float32(edge)) }

    var bitmapOut = Bitmap(wo, ho, 4)
    bitmapOut.allocCdata()
    let res = unsafe { tfTask(bitmapOut.cdata, bitmap.cdata, pfParam) }
    bitmapOut.cdataToData()

    for (i in 0..4) {
      AppLog.error("gl_log CircleCrop out : ${bitmap.data[i]}, ${bitmapOut.data[i]}, ${res}")
    }

     let color:Array<UInt8> = Array<UInt8>(bitmapOut.data.size,item:0)
     let px:PixelMap = createPixelMap(color,InitializationOptions(size: Size(width: wo, height: ho), pixelFormat: PixelMapFormat.RGBA_8888, editable: true))
    //var px = PixelMap([UInt32(1)], 1, InitializationOptions(Size(width: wo, height: ho)))

    px.writeBufferToPixels(bitmapOut.data)
    bitmap.release()
    bitmapOut.release()
    unsafe { free(puParam) }
    return px
  }

  public func toString(): String {
    //return ID
    return "CircleCrop()";
  }

  public func hashCode(): Int64 {
    //return ID.hashCode()
    Utils.hashCodeWrite(ID, reset: true)
    return Utils.hashCodeFinish()
  }

  public operator func ==(that: AnyKey): Bool {
    if (that is CircleCrop) {
      return true
    } else {
      return false
    }
  }

  public operator func !=(that: AnyKey): Bool {
    if(that is CircleCrop) {
      return false
    } else {
      return true
    }
  }

  public func updateDiskCacheKey(md5: MD5) {
    md5.MD5Update("${ID}".toArray())  //update data
  }
}

public class RoundedCorners <: PixelMapTransformation {

  private static let ID: String = "com.bumptech.glide.load.resource.bitmap.RoundedCorners"
  private static let tfId: UInt32 = unsafe { getRoundedcornersIdx() }
  var radius: Int32

  public init(radius: Int32) {
    if(radius <= 0) {
      throw GlideException("radius must be greater than 0.")
    }
    this.radius = radius
    nParam = 8
  }

  protected func transform(toTransform: PixelMap, outWidth: Int64, outHeight: Int64): PixelMap {

    //let (ii, arr) = toTransform.readPixelsToBuffer(UInt64(toTransform.getPixelBytesNumber()))
        let arr :Array<UInt8> = Array<UInt8>(Int64(toTransform.getPixelBytesNumber()),item:0)
            toTransform.readPixelsToBuffer(arr)
    var info = toTransform.getImageInfo()
    var w = info.size.width
    var h = info.size.height
    AppLog.error("gl_log RoundedCorners : ${radius}, ${w}, ${h}, ${arr.size}")
    var bitmap = Bitmap(w, h, 4, arr)
    //var bitmap = Bitmap(w, h, 4, Path("/home/yaoy/cj/srcnew/messi480p.bin.bmp"))
    var bitmapOut = Bitmap(w, h, 4)
    bitmapOut.allocCdata()

    puParam = unsafe { malloc(UIntNative(maxNumParam * szofParam)) }
    pfParam = unsafe { CPointer<Float32>(puParam) }
    unsafe { pfParam.write(0, Float32(tfId)) }
    unsafe { pfParam.write(1, Float32(w)) }
    unsafe { pfParam.write(2, Float32(h)) }
    unsafe { pfParam.write(3, Float32(4)) }
    unsafe { pfParam.write(4, Float32(radius)) }
    unsafe { pfParam.write(5, Float32(radius)) }
    unsafe { pfParam.write(6, Float32(radius)) }
    unsafe { pfParam.write(7, Float32(radius)) }
    let res = unsafe { tfTask(bitmapOut.cdata, bitmap.cdata, pfParam) }
    bitmapOut.cdataToData()

    for (i in 0..4) {
      AppLog.error("gl_log contrast out : ${bitmap.data[i]}, ${bitmapOut.data[i]}, ${radius}, ${res}")
    }

     let color:Array<UInt8> = Array<UInt8>(bitmapOut.data.size,item:0)
    let px:PixelMap = createPixelMap(color,InitializationOptions(size: info.size, pixelFormat: PixelMapFormat.RGBA_8888, editable: true))
    //var px = PixelMap([UInt32(1)], 1, InitializationOptions(info.size))
    px.writeBufferToPixels(bitmapOut.data)
    bitmap.release()
    bitmapOut.release()
    unsafe { free(puParam) }
    return px
  }

  public func toString(): String {
    //return ID
    return "RoundedCorners(radius=${radius})";
  }

  public func hashCode(): Int64 {
    //return ID.hashCode()
    Utils.hashCodeWrite(ID, reset: true)
    Utils.hashCodeWrite(Int64(radius))
    return Utils.hashCodeFinish()
  }

  public operator func ==(that: AnyKey): Bool {
    if (that is RoundedCorners) {
      var other: RoundedCorners = (that as RoundedCorners).getOrThrow();
      return radius == other.radius
    } else {
      return false
    }
  }

  public operator func !=(that: AnyKey): Bool {
    if(that is RoundedCorners) {
      var other: RoundedCorners = (that as RoundedCorners).getOrThrow();
      return radius != other.radius
    } else {
      return true
    }
  }

  public func updateDiskCacheKey(md5: MD5) {
    md5.MD5Update("${ID}${radius}".toArray())  //update data
  }
}

public class GranularRoundedCorners <: PixelMapTransformation {

  private static let ID: String = "com.bumptech.glide.load.resource.bitmap.GranularRoundedCorners"
  private static let tfId: UInt32 = unsafe { getRoundedcornersIdx() }
  var radiusTL: Int32
  var radiusTR: Int32
  var radiusBL: Int32
  var radiusBR: Int32

  public init(radiusTL: Int32, radiusTR: Int32, radiusBL: Int32, radiusBR: Int32) {
    if(radiusTL < 0 || radiusTR < 0 || radiusBL < 0 || radiusBR < 0) {
      throw GlideException("radius must not be less than 0.")
    }
    this.radiusTL = radiusTL
    this.radiusTR = radiusTR
    this.radiusBL = radiusBL
    this.radiusBR = radiusBR
    nParam = 5
  }

  protected func transform(toTransform: PixelMap, outWidth: Int64, outHeight: Int64): PixelMap {

    //let (ii, arr) = toTransform.readPixelsToBuffer(UInt64(toTransform.getPixelBytesNumber()))
        let arr :Array<UInt8> = Array<UInt8>(Int64(toTransform.getPixelBytesNumber()),item:0)
            toTransform.readPixelsToBuffer(arr)
    var info = toTransform.getImageInfo()
    var w = info.size.width
    var h = info.size.height
    AppLog.error("gl_log GranularRoundedCorners : ${radiusTL}, ${radiusTR}, ${radiusBL}, ${radiusBR}, ${w}, ${h}, ${arr.size}")
    var bitmap = Bitmap(w, h, 4, arr)
    //var bitmap = Bitmap(w, h, 4, Path("/home/yaoy/cj/srcnew/messi480p.bin.bmp"))
    var bitmapOut = Bitmap(w, h, 4)
    bitmapOut.allocCdata()

    puParam = unsafe { malloc(UIntNative(maxNumParam * szofParam)) }
    pfParam = unsafe { CPointer<Float32>(puParam) }
    unsafe { pfParam.write(0, Float32(tfId)) }
    unsafe { pfParam.write(1, Float32(w)) }
    unsafe { pfParam.write(2, Float32(h)) }
    unsafe { pfParam.write(3, Float32(4)) }
    unsafe { pfParam.write(4, Float32(radiusBL)) }
    unsafe { pfParam.write(5, Float32(radiusBR)) }
    unsafe { pfParam.write(6, Float32(radiusTL)) }
    unsafe { pfParam.write(7, Float32(radiusTR)) }
    let res = unsafe { tfTask(bitmapOut.cdata, bitmap.cdata, pfParam) }
    bitmapOut.cdataToData()

    for (i in 0..4) {
      AppLog.error("gl_log GranularRoundedCorners out : ${bitmap.data[i]}, ${bitmapOut.data[i]}, ${res}")
    }

     let color:Array<UInt8> = Array<UInt8>(bitmapOut.data.size,item:0)
     let px:PixelMap = createPixelMap(color,InitializationOptions(size: info.size, pixelFormat: PixelMapFormat.RGBA_8888, editable: true))
    //var px = PixelMap([UInt32(1)], 1, InitializationOptions(info.size))
    px.writeBufferToPixels(bitmapOut.data)
    bitmap.release()
    bitmapOut.release()
    unsafe { free(puParam) }
    return px
  }

  public func toString(): String {
    //return ID
    return "GranularRoundedCorners(radiusTL=${radiusTL},radiusTR=${radiusTR},radiusBL=${radiusBL},radiusBR=${radiusBR})";
  }

  public func hashCode(): Int64 {
    //return ID.hashCode()
    Utils.hashCodeWrite(ID, reset: true)
    Utils.hashCodeWrite(Int64(radiusTL))
    Utils.hashCodeWrite(Int64(radiusTR))
    Utils.hashCodeWrite(Int64(radiusBL))
    Utils.hashCodeWrite(Int64(radiusBR))
    return Utils.hashCodeFinish()
  }

  public operator func ==(that: AnyKey): Bool {
    if (that is GranularRoundedCorners) {
      var other: GranularRoundedCorners = (that as GranularRoundedCorners).getOrThrow();
      return ((radiusTL == other.radiusTL) && (radiusTR == other.radiusTR) && (radiusBL == other.radiusBL) && (radiusBR == other.radiusBR))
    } else {
      return false
    }
  }

  public operator func !=(that: AnyKey): Bool {
    if(that is GranularRoundedCorners) {
      var other: GranularRoundedCorners = (that as GranularRoundedCorners).getOrThrow();
      return !((radiusTL == other.radiusTL) && (radiusTR == other.radiusTR) && (radiusBL == other.radiusBL) && (radiusBR == other.radiusBR))
    } else {
      return true
    }
  }

  public func updateDiskCacheKey(md5: MD5) {
    md5.MD5Update("${ID}${radiusTL}${radiusTR}${radiusBL}${radiusBR}".toArray())  //update data
  }
}

public class FastBlur <: PixelMapTransformation {

  private static let ID: String = "com.bumptech.glide.load.resource.bitmap.FastBlur"
  private static let tfId: UInt32 = unsafe { getFastBlurIdx() }
  var radius: Int32

  public init(radius: Int32) {
    if(radius <= 0) {
      throw GlideException("radius must be greater than 0.")
    }
    this.radius = radius
    nParam = 5
  }

  protected func transform(toTransform: PixelMap, outWidth: Int64, outHeight: Int64): PixelMap {

    //let (ii, arr) = toTransform.readPixelsToBuffer(UInt64(toTransform.getPixelBytesNumber()))
        let arr :Array<UInt8> = Array<UInt8>(Int64(toTransform.getPixelBytesNumber()),item:0)
            toTransform.readPixelsToBuffer(arr)
    var info = toTransform.getImageInfo()
    var w = info.size.width
    var h = info.size.height
    AppLog.error("gl_log FastBlur : ${radius}, ${w}, ${h}, ${arr.size}")
    var bitmap = Bitmap(w, h, 4, arr)
    //var bitmap = Bitmap(w, h, 4, Path("/home/yaoy/cj/srcnew/messi480p.bin.bmp"))
    var bitmapOut = Bitmap(w, h, 4)
    bitmapOut.allocCdata()

    puParam = unsafe { malloc(UIntNative(maxNumParam * szofParam)) }
    pfParam = unsafe { CPointer<Float32>(puParam) }
    unsafe { pfParam.write(0, Float32(tfId)) }
    unsafe { pfParam.write(1, Float32(w)) }
    unsafe { pfParam.write(2, Float32(h)) }
    unsafe { pfParam.write(3, Float32(4)) }
    unsafe { pfParam.write(4, Float32(radius)) }
    let res = unsafe { tfTask(bitmapOut.cdata, bitmap.cdata, pfParam) }
    bitmapOut.cdataToData()

    for (i in 0..4) {
      AppLog.error("gl_log FastBlur out : ${bitmap.data[i]}, ${bitmapOut.data[i]}, ${radius}, ${res}")
    }

      let color:Array<UInt8> = Array<UInt8>(bitmapOut.data.size,item:0)
     let px:PixelMap = createPixelMap(color,InitializationOptions(size: info.size, pixelFormat: PixelMapFormat.RGBA_8888, editable: true))
    //var px = PixelMap([UInt32(1)], 1, InitializationOptions(info.size))
    px.writeBufferToPixels(bitmapOut.data)
    bitmap.release()
    bitmapOut.release()
    unsafe { free(puParam) }
    return px
  }

  public func toString(): String {
    //return ID
    return "FastBlur(radius=${radius})";
  }

  public func hashCode(): Int64 {
    //return ID.hashCode()
    Utils.hashCodeWrite(ID, reset: true)
    Utils.hashCodeWrite(Int64(radius))
    return Utils.hashCodeFinish()
  }

  public operator func ==(that: AnyKey): Bool {
    if (that is FastBlur) {
      var other: FastBlur = (that as FastBlur).getOrThrow();
      return radius == other.radius
    } else {
      return false
    }
  }

  public operator func !=(that: AnyKey): Bool {
    if(that is FastBlur) {
      var other: FastBlur = (that as FastBlur).getOrThrow();
      return radius != other.radius
    } else {
      return true
    }
  }

  public func updateDiskCacheKey(md5: MD5) {
    md5.MD5Update("${ID}${radius}".toArray())  //update data
  }
}