/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2023-2024. All rights resvered.
 */
 
package droplet.droplet



public enum ImageType {
    GIF |
    PNG |
    JPEG |
    BMP
}



public interface ImageReader {

  func decodePixelMap(targetWidth: Int32, targetHeight: Int32): Option<PixelMap>;

  func stopGrowingBuffers(): Unit;

    func getWidth(): Int32;
    func getHeight(): Int32;

}

public class ByteArrayReader <: ImageReader {

    private let bytes: Array<UInt8>;

    private let imageSource: ImageSource;
    public let info: ImageInfo;


    public init(bytes: Array<UInt8>) {
      this.bytes = bytes;

      var size: Size = Size(width: 1, height: 1)
        var sourceOptions: SourceOptions = SourceOptions(sourceSize: size)
        this.imageSource = createImageSource(this.bytes, sourceOptions)
        this.info = imageSource.getImageInfo()
    }

    public func decodePixelMap(targetWidth: Int32, targetHeight: Int32): Option<PixelMap> {


        let desiredSize: Size = Size(width: targetWidth, height: targetHeight) // 548 342

        let regionSize: Size = Size(width: this.info.size.width, height: this.info.size.height)
        let desiredRegion: Region = Region(regionSize, 0, 0)

        let decodingOptions = DecodingOptions(
            rotate: 0, //rotate: UInt32, //旋转角度。
            desiredSize: desiredSize, //desiredSize: Size, //期望输出大小。
            desiredRegion: desiredRegion, //desiredRegion: Region, //解码区域。
            index: 0, //index: Int32, //解码图片序号。
            desiredPixelFormat: PixelMapFormat.RGBA_8888, //解码的像素格式。
            editable: true,
            sampleSize: 1
        )

        let pixelMap: PixelMap = imageSource.createPixelMap(options: decodingOptions)

      return Some(pixelMap);
    }

    public func stopGrowingBuffers(): Unit {}

    public func getWidth(): Int32 {
        return info.size.width
    }

    public func getHeight(): Int32 {
        return info.size.height
    }
}



public class Downsampler {

    public static let SIZE_ORIGINAL: Int64 = -0x7FFFFFFFFFFFFFFF


    /**
   * Returns a Bitmap decoded from the given {@link InputStream} that is rotated to match any EXIF
   * data present in the stream and that is downsampled according to the given dimensions and any
   * provided {@link com.bumptech.droplet.load.resource.bitmap.DownsampleStrategy} option.
   *
   * @see #decode(InputStream, int, int, Options, DecodeCallbacks)
   */


    /**
   * Identical to {@link #decode(InputStream, int, int, Options)}, except that it accepts a {@link
   * ByteBuffer} in place of an {@link InputStream}.
   */
  public func decode(buffer: Array<UInt8>, requestedWidth: Int64, requestedHeight: Int64, options: DropletOptions): Option<DropletResource<PixelMapDrawable>> {
    return decode(
        ByteArrayReader(buffer),
        requestedWidth,
        requestedHeight,
        options,
        );
  }

  public func decodeDrawable(buffer: Array<UInt8>, requestedWidth: Int64, requestedHeight: Int64, options: DropletOptions): Option<PixelMapDrawable> {
    return decodeDrawable(
        ByteArrayReader(buffer),
        requestedWidth,
        requestedHeight,
        options,
        );
  }

  public func decodePixelMap(buffer: Array<UInt8>, requestedWidth: Int64, requestedHeight: Int64, options: DropletOptions): Option<PixelMap> {
    return decodePixelMap(
        ByteArrayReader(buffer),
        requestedWidth,
        requestedHeight,
        options,
        );
  }

    // TODO 暂时不用解码inputstream

    private func decode(
      imageReader: ImageReader,
      requestedWidth: Int64,
        requestedHeight: Int64,
        options: DropletOptions
        ): Option<DropletResource<PixelMapDrawable>> {
    let downsampleStrategy: DownsampleStrategy = options.get(DownsampleStrategy.OPTION);

      let result: Option<PixelMap> =
          decodeFromWrappedStreams(
              imageReader,
              downsampleStrategy,
              requestedWidth,
              requestedHeight
                )


    if(match(result) {
        case Some(x) => true
        case _ => false
    }) {
        let pixelMap: PixelMap = result.getOrThrow()
        let drawable: PixelMapDrawable = PixelMapDrawable(pixelMap)
        return Some(PixelMapDrawableResource.obtain(drawable));
    } else {
        return None
    }
      
  }

  private static func calculateScaling(
      downsampleStrategy: DownsampleStrategy,
      sourceWidth: Int64,
      sourceHeight: Int64,
      targetWidth: Int64,
      targetHeight: Int64): (Int32, Int32) {
    // We can't downsample source content if we can't determine its dimensions.
    if (sourceWidth <= 0 || sourceHeight <= 0) {
      return (0, 0);
    }

    // 确认下采样策略
    let orientedSourceWidth: Int64 = sourceWidth;
    let orientedSourceHeight: Int64 = sourceHeight;

    // 获取精确缩放因子
    var exactScaleFactor: Float64 =
        downsampleStrategy.getScaleFactor(
            orientedSourceWidth, orientedSourceHeight, targetWidth, targetHeight);


    if (exactScaleFactor <= 0.0) {
        throw DropletException("Cannot scale with factor")
    }else if(exactScaleFactor > 1.0){
            exactScaleFactor = 1.0
    }

    // 采样大小舍入规则
    let rounding: SampleSizeRounding =
        downsampleStrategy.getSampleSizeRounding(
            orientedSourceWidth, orientedSourceHeight, targetWidth, targetHeight);

    let outWidth: Int32 = Int32(round(exactScaleFactor * Float64(orientedSourceWidth)));
    let outHeight: Int32 = Int32(round(exactScaleFactor * Float64(orientedSourceHeight)));
    return (outWidth, outHeight)

  }

  private func decodeDrawable(
      imageReader: ImageReader,
      requestedWidth: Int64,
        requestedHeight: Int64,
        options: DropletOptions
        ): Option<PixelMapDrawable> {

    let result = decodePixelMap(imageReader, requestedWidth, requestedHeight, options)

    if(match(result) {
        case Some(x) => true
        case _ => false
    }) {
        let pixelMap: PixelMap = result.getOrThrow()
        let drawable: PixelMapDrawable = PixelMapDrawable(pixelMap)
        return Some(drawable);
    } else {
        return None
    }
      
  }

  private func decodePixelMap(
      imageReader: ImageReader,
      requestedWidth: Int64,
        requestedHeight: Int64,
        options: DropletOptions
        ): Option<PixelMap> {

    let downsampleStrategy: DownsampleStrategy = options.get(DownsampleStrategy.OPTION);

    let result: Option<PixelMap> =
        decodeFromWrappedStreams(
            imageReader,
            downsampleStrategy,
            requestedWidth,
            requestedHeight
            )

    return result
      
  }


  private func decodeFromWrappedStreams(
      imageReader: ImageReader,
      downsampleStrategy: DownsampleStrategy,
      requestedWidth: Int64,
      requestedHeight: Int64
      ): Option<PixelMap> {

        // BitmapFactory.Options选项
        // inBitmap——在解析Bitmap时重用该Bitmap，不过必须等大的Bitmap而且inMutable须为true
        // inMutable——配置Bitmap是否可以更改，比如：在Bitmap上隔几个像素加一条线段
        // inJustDecodeBounds——为true仅返回Bitmap的宽高等属性
        // inSampleSize——须>=1,表示Bitmap的压缩比例，如：inSampleSize=4，将返回一个是原始图的1/16大小的Bitmap
        // inPreferredConfig——Bitmap.Config.ARGB_8888等
        // inDither——是否抖动，默认为false
        // inPremultiplied——默认为true，一般不改变它的值
        // inDensity——Bitmap的像素密度
        // inTargetDensity——Bitmap最终的像素密度
        // inScreenDensity——当前屏幕的像素密度
        // inScaled——是否支持缩放，默认为true，当设置了这个，Bitmap将会以inTargetDensity的值进行缩放
        // inPurgeable——当存储Pixel的内存空间在系统内存不足时是否可以被回收
        // inInputShareable——inPurgeable为true情况下才生效，是否可以共享一个InputStream
        // inPreferQualityOverSpeed——为true则优先保证Bitmap质量其次是解码速度
        // outWidth——返回的Bitmap的宽
        // outHeight——返回的Bitmap的高
        // inTempStorage——解码时的临时空间，建议16*1024


    // 图片宽高
    let sourceWidth: Int64 = Int64(imageReader.getWidth())
    let sourceHeight: Int64 = Int64(imageReader.getHeight())

    let targetWidth: Int64 =
        if(requestedWidth == SIZE_ORIGINAL) {
            sourceWidth
        } else {
            requestedWidth
        }

    let targetHeight: Int64 =
        if(requestedHeight == SIZE_ORIGINAL) {
            sourceHeight
        } else {
            requestedHeight
        }

    let (finalWidth, finalHeight) = calculateScaling(
        downsampleStrategy,
        sourceWidth,
        sourceHeight,
        targetWidth,
        targetHeight);

    let downsampled: Option<PixelMap> = imageReader.decodePixelMap(finalWidth, finalHeight)

    if(match(downsampled) {
        case Some(x) => false
        case _ => true
    }) {
        return None
    }

    // calculateScaling 缩放图片适合显示区域  scaling 缩放倍数

    // TODO 缩放图片resize

    return downsampled
  }

}