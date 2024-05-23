package glide

from ohos import image.*

from std import io.*

public class PixelMapDrawableResource <: GlideResource<PixelMapDrawable> {
  private var pixelMapDrawable: PixelMapDrawable;

  public static func obtain(pixelMapDrawable: PixelMapDrawable): PixelMapDrawableResource {
    return PixelMapDrawableResource(pixelMapDrawable);
  }

  public override func getResourceTypeClass(): ResourceTypeClass {
    return ResourceTypeClass.RESOURCE_TYPE_PIXELMAP
  }

  public override func get(): PixelMapDrawable {
    return pixelMapDrawable;
  }

  public override func getAsAny(): Any {
    return (pixelMapDrawable as Any).getOrThrow()
  }

  public override func getSize(): Int32 {
    let pixelMap: PixelMap = pixelMapDrawable.getPixelMap()
    // let (ii, arr) = pixelMap.readPixelsToBuffer(UInt64(pixelMap.getPixelBytesNumber()))
    // return arr.size;
    //适配
    //return pixelMap.getPixelBytesNumber()
    return Int32(pixelMap.getPixelBytesNumber())
  }

  public override func recycle(): Unit {
    
  }

  public init(pixelMapDrawable: PixelMapDrawable) {
    this.pixelMapDrawable = pixelMapDrawable
  }

  public func toString(): String {
    // TODO PixelMap toString
      // return this.pixelMap.toString()
      return "pixelMapDrawableResource"
  }

  public func hashCode(): Int64 {
    // TODO PixelMap hashCode
      // return this.pixelMap.hashCode()
      return 0
  }

  public operator func ==(that: AnyGlideResource): Bool {
    // TODO PixelMap ==
    if(that is GlideResource<PixelMapDrawable>) {
      return true
    }
    return false
      // return that.get() == this.get()
  }

  public operator func !=(that: AnyGlideResource): Bool {
    // TODO PixelMap !=
    if(that is GlideResource<PixelMapDrawable>) {
      return false
    }
    return true
      // return that.get() != this.get()
  }

  public func copy(): GlideResource<PixelMapDrawable> {
    return this
  }

}

public class PixelMapResource <: GlideResource<PixelMap> {
  private var pixelMap: PixelMap;

  public static func obtain(pixelMap: PixelMap): PixelMapResource {
    return PixelMapResource(pixelMap);
  }

  public override func getResourceTypeClass(): ResourceTypeClass {
    return ResourceTypeClass.RESOURCE_TYPE_PIXELMAP
  }

  public override func get(): PixelMap {
    return pixelMap;
  }

  public override func getAsAny(): Any {
    return (pixelMap as Any).getOrThrow()
  }

  public override func getSize(): Int32 {
    // TODO PixelMap getSize
    // return pixelMap.size()
    //适配
    //return pixelMap.getPixelBytesNumber();
    return Int32(pixelMap.getPixelBytesNumber())
  }

  public override func recycle(): Unit {
    
  }

  public init(pixelMap: PixelMap) {
    this.pixelMap = pixelMap
  }

  public func toString(): String {
    // TODO PixelMap toString
      // return this.pixelMap.toString()
      return "pixelMapResource"
  }

  public func hashCode(): Int64 {
    // TODO PixelMap hashCode
      // return this.pixelMap.hashCode()
      return 0
  }

  public operator func ==(that: AnyGlideResource): Bool {
    // TODO PixelMap ==
    if(that is GlideResource<PixelMap>) {
      return true
    }
    return false
      // return that.get() == this.get()
  }

  public operator func !=(that: AnyGlideResource): Bool {
    // TODO PixelMap !=
    if(that is GlideResource<PixelMap>) {
      return false
    }
    return true
      // return that.get() != this.get()
  }

  public func copy(): GlideResource<PixelMap> {
    return this
  }

}

public class InputStreamResource <: GlideResource<InputStream> {
  private var inputStream: InputStream;

  public static func obtain(inputStream: InputStream): InputStreamResource {
    return InputStreamResource(inputStream);
  }

  public override func getResourceTypeClass(): ResourceTypeClass {
    return ResourceTypeClass.RESOURCE_TYPE_INPUTSTREAM
  }

  public override func get(): InputStream {
    return inputStream;
  }

  public override func getAsAny(): Any {
    return (inputStream as Any).getOrThrow()
  }

  public override func getSize(): Int32 {
    //适配
    //return Int32(inputStream.length);
    var size = match(inputStream as Seekable) {
        case Some(v) => v.remainLength
        case None => 0
    }
    return Int32(size)
  }

  public override func recycle(): Unit {
    
  }

  public init(inputStream: InputStream) {
    this.inputStream = inputStream
  }

  public func toString(): String {
    // TODO InputStreamResource toString
      // return this.pixelMap.toString()
      return "inputStreamResource"
  }

  public func hashCode(): Int64 {
    // TODO InputStreamResource hashCode
      // return this.pixelMap.hashCode()
      return 0
  }

  public operator func ==(that: AnyGlideResource): Bool {
    // TODO InputStreamResource ==
    if(that is GlideResource<InputStream>) {
      return true
    }
    return false
      // return that.get() == this.get()
  }

  public operator func !=(that: AnyGlideResource): Bool {
    // TODO InputStreamResource !=
    if(that is GlideResource<InputStream>) {
      return false
    }
    return true
      // return that.get() != this.get()
  }

  public func copy(): GlideResource<InputStream> {
    if(inputStream is ByteArrayStream) {
      return InputStreamResource((inputStream as ByteArrayStream).getOrThrow().clone())
    }
    return this
  }

}

public class BytesResource <: GlideResource<Array<UInt8>> {
  public let bytes: Array<UInt8>;

  public BytesResource(bytes: Array<UInt8>) {
    this.bytes = bytes;
  }

  public override func getResourceTypeClass(): ResourceTypeClass {
    return ResourceTypeClass.RESOURCE_TYPE_ARRAY
  }

  public override func get(): Array<UInt8> {
    return bytes;
  }

  public override func getAsAny(): Any {
    return (bytes as Any).getOrThrow()
  }

  public override func getSize(): Int32 {
    return Int32(bytes.size);
  }

  public override func recycle(): Unit {
    
  }

  public func toString(): String {
      return "byteresource:${bytes}_${bytes.size}"
  }

  public func hashCode(): Int64 {
    Utils.hashCodeWrite<UInt8>(bytes, reset: true)
    return Utils.hashCodeFinish()
  }

  public operator func ==(that: AnyGlideResource): Bool {
    if(that is BytesResource) {
      let other = (that as BytesResource).getOrThrow()
      return other.bytes == bytes
    }
    return false
  }

  public operator func !=(that: AnyGlideResource): Bool {
    if(that is BytesResource) {
      let other = (that as BytesResource).getOrThrow()
      return other.bytes != bytes
    }
    return true
  }

  public func copy(): GlideResource<Array<UInt8>> {
    return this
  }
}
