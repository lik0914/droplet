package glide

from ohos import image.*
from ohos import base.*

public interface Encoder<T> {
  /**
   * Writes the given data to the given output stream and returns True if the write completed
   * successfully and should be committed.
   *
   * @param data The data to write.
   * @param file The file to write the data to.
   * @param options The set of options to apply when encoding.
   */
  func encode(data: T, file: GlideFile, options: GlideOptions): Bool;
}

public interface AnyResourceEncoder {
  // specializing the generic arguments
  func getEncodeStrategy(options: GlideOptions): EncodeStrategy;
}

public interface ResourceEncoder<T> <: Encoder<GlideResource<T>> & AnyResourceEncoder {
  
}

public class PixelMapEncoder <: ResourceEncoder<PixelMap> {
  public func getEncodeStrategy(options: GlideOptions): EncodeStrategy {
    return EncodeStrategy.TRANSFORMED
  }

  public func encode(data: GlideResource<PixelMap>, file: GlideFile, options: GlideOptions): Bool {
    let pixelMap: PixelMap = data.get()
    let info = pixelMap.getImageInfo()
    // AppLog.error("pixelmap encode begin1: ${info.size.width} - ${info.size.height}")
    // AppLog.error("pixelmap encode begin2: ${file.filePath.toString()} - ${UInt64(pixelMap.getPixelBytesNumber())}")
    //适配
    //let (ii, arr) = pixelMap.readPixelsToBuffer(UInt64(pixelMap.getPixelBytesNumber()))
    let arr: Array<UInt8> = Array<UInt8>(Int64(pixelMap.getPixelBytesNumber()), item: 0)
    pixelMap.readPixelsToBuffer(arr)
    if(arr.size > 0) {
      let width: Int32 = info.size.width
      let height: Int32 = info.size.height
      let imageInfoArr: Array<UInt8> = Array<UInt8>(4, item: 0)
      imageInfoArr[0] = UInt8(width >> 8 & 0xFF);
      imageInfoArr[1] = UInt8(width & 0xFF);
      imageInfoArr[2] = UInt8(height >> 8 & 0xFF);
      imageInfoArr[3] = UInt8(height & 0xFF);
      let f = file.getFile()
      f.write(imageInfoArr)
      f.write(arr)
      f.flush()
      f.close()
    }
    return true
  }
}

public class PixelMapDrawableEncoder <: ResourceEncoder<PixelMapDrawable> {
  public func getEncodeStrategy(options: GlideOptions): EncodeStrategy {
    return EncodeStrategy.TRANSFORMED
  }

  public func encode(data: GlideResource<PixelMapDrawable>, file: GlideFile, options: GlideOptions): Bool {
    // AppLog.error("pixelmap drawable encode begin: ${file.filePath.toString()}")
    let pixelMap: PixelMap = data.get().getPixelMap()
    let info = pixelMap.getImageInfo()
    
    // AppLog.error("pixelmap drawable encode begin1: ${info.size.width} -- ${info.size.height}")
    //适配
    //let (ii, arr) = pixelMap.readPixelsToBuffer(UInt64(pixelMap.getPixelBytesNumber()))
    let arr: Array<UInt8> = Array<UInt8>(Int64(pixelMap.getPixelBytesNumber()), item: 0)
    pixelMap.readPixelsToBuffer(arr)

    // AppLog.error("pixelmap drawable encode begin1: ${info.size.width} - ${info.size.height}")
    // AppLog.error("pixelmap drawable encode begin2: ${file.filePath.toString()} - ${UInt64(pixelMap.getPixelBytesNumber())}  - ${arr.size}")
    if(arr.size > 0) {
      let width: Int32 = info.size.width
      let height: Int32 = info.size.height
      let imageInfoArr: Array<UInt8> = Array<UInt8>(4, item: 0)
      imageInfoArr[0] = UInt8(width >> 8 & 0xFF);
      imageInfoArr[1] = UInt8(width & 0xFF);
      imageInfoArr[2] = UInt8(height >> 8 & 0xFF);
      imageInfoArr[3] = UInt8(height & 0xFF);
      let f = file.getFile()
      f.write(imageInfoArr)
      f.write(arr)
      f.flush()
      f.close()
    }
    return true
  }
}

