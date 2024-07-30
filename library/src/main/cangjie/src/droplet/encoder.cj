/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2023-2024. All rights resvered.
 */

package droplet.droplet



public interface Encoder<T> {
  /**
   * Writes the given data to the given output stream and returns True if the write completed
   * successfully and should be committed.
   *
   * @param data The data to write.
   * @param file The file to write the data to.
   * @param options The set of options to apply when encoding.
   */
  func encode(data: T, file: DropletFile, options: DropletOptions): Bool;
}

public interface AnyResourceEncoder {
  // specializing the generic arguments
  func getEncodeStrategy(options: DropletOptions): EncodeStrategy;
}

public interface ResourceEncoder<T> <: Encoder<DropletResource<T>> & AnyResourceEncoder {
  
}

public class PixelMapEncoder <: ResourceEncoder<PixelMap> {
  public func getEncodeStrategy(options: DropletOptions): EncodeStrategy {
    return EncodeStrategy.TRANSFORMED
  }

  public func encode(data: DropletResource<PixelMap>, file: DropletFile, options: DropletOptions): Bool {
    let pixelMap: PixelMap = data.get()
    let info = pixelMap.getImageInfo()
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
  public func getEncodeStrategy(options: DropletOptions): EncodeStrategy {
    return EncodeStrategy.TRANSFORMED
  }

  public func encode(data: DropletResource<PixelMapDrawable>, file: DropletFile, options: DropletOptions): Bool {
    let pixelMap: PixelMap = data.get().getPixelMap()
    let info = pixelMap.getImageInfo()
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

