package glide.model

from std import io.*
import glide.load.resource.*
import glide.engine.cache.*
from std import math.*

import glide.util.exceptions.*

from ohos import image.*

public enum ImageType {
    GIF |
    PNG |
    JPEG |
    BMP
}

public interface ImageHeaderParser {

  func getType(inputStream: InputStream): ImageType;

  func getType(array: Array<UInt8>): ImageType;

  /**
   * Parse the orientation from the image header. If it doesn't handle this image type (or this is
   * not an image) it will return a default value rather than throwing an exception.
   *
   * @return The exif orientation if present or -1 if the header couldn't be parsed or doesn't
   *     contain an orientation
   */
  func getOrientation(inputStream: InputStream): Int64;

  func getOrientation(array: Array<UInt8>): Int64;
}

// TODO ImageHeaderParser
public class DefaultImageHeaderParser <: ImageHeaderParser {
    public func getType(inputStream: InputStream): ImageType {
        ImageType.BMP
    }

    public func getType(array: Array<UInt8>): ImageType {
        ImageType.BMP
    }

    public func getOrientation(inputStream: InputStream): Int64 {
        return 0
    }

    public func getOrientation(array: Array<UInt8>): Int64 {
        return 0
    }
}

public interface ImageReader {

  func decodePixelMap(targetWidth: Int32, targetHeight: Int32): Option<PixelMap>;

  func getImageType(): ImageType;

  func getImageOrientation(): Int64;

  func stopGrowingBuffers(): Unit;

    func getWidth(): Int32;
    func getHeight(): Int32;

}

public class ByteArrayReader <: ImageReader {

    private let bytes: Array<UInt8>;
    private let imageHeaderParser: ImageHeaderParser;
    private let imageSource: ImageSource;
    public let info: ImageInfo;
    // private let parsers: List<ImageHeaderParser>;
    // private let ArrayPool byteArrayPool;

    public init(bytes: Array<UInt8>, imageHeaderParser: ImageHeaderParser) {
      this.bytes = bytes;
      this.imageHeaderParser = imageHeaderParser;
      var size: Size = Size(width: 1, height: 1)
        //适配
        //var sourceOptions: SourceOptions = SourceOptions(size)
        var sourceOptions: SourceOptions = SourceOptions(sourceSize: size)
        //适配
        //this.imageSource = ImageAbility.createImageSource(this.bytes, sourceOptions)
        this.imageSource = image.createImageSource(this.bytes, sourceOptions)
        this.info = imageSource.getImageInfo()
    }

    public func decodePixelMap(targetWidth: Int32, targetHeight: Int32): Option<PixelMap> {

        // AppLog.info("decodePixelMap : ImageSource.ID is ${imageSource.getID()}-----------------------------------1")

        let desiredSize: Size = Size(width: targetWidth, height: targetHeight) // 548 342

        let regionSize: Size = Size(width: this.info.size.width, height: this.info.size.height)
        //适配
        //let desiredRegion: Region = Region(regionSize, left: 0, top: 0)
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

        //适配
        //let pixelMap: PixelMap = imageSource.createPixelMap(Some(decodingOptions))
        let pixelMap: PixelMap = imageSource.createPixelMap(options: decodingOptions)
        // AppLog.error("PixelMap.ID is ${pixelMap.getID()}-----------------------------------2")

      return Some(pixelMap);
    }

    public func getImageType(): ImageType {
      return imageHeaderParser.getType(bytes);
    }

    public func getImageOrientation(): Int64 {
      return imageHeaderParser.getOrientation(bytes);
    }

    public func stopGrowingBuffers(): Unit {}

    public func getWidth(): Int32 {
        return info.size.width
    }

    public func getHeight(): Int32 {
        return info.size.height
    }
}

public interface DecodeCallbacks {
    func onObtainBounds(): Unit;

    func onDecodeComplete(downsampled: PixelMap): Unit;
}

public class EmptyCallbacks <: DecodeCallbacks {
    public func onObtainBounds(): Unit {}

    public func onDecodeComplete(downsampled: PixelMap): Unit {}
}

public class Downsampler {

    public static let SIZE_ORIGINAL: Int64 = -0x7FFFFFFFFFFFFFFF

    public static let EMPTY_CALLBACKS: EmptyCallbacks = EmptyCallbacks()

    /**
   * Returns a Bitmap decoded from the given {@link InputStream} that is rotated to match any EXIF
   * data present in the stream and that is downsampled according to the given dimensions and any
   * provided {@link com.bumptech.glide.load.resource.bitmap.DownsampleStrategy} option.
   *
   * @see #decode(InputStream, int, int, Options, DecodeCallbacks)
   */
//   public func decode(inputStream: InputStream, outWidth: Int64, outHeight: Int64, options: GlideOptions): GlideResource<PixelMap> {
//     return decode(inputStream, 
//                     outWidth, 
//                     outHeight, 
//                     options, 
//                     EMPTY_CALLBACKS);
//   }

    /**
   * Identical to {@link #decode(InputStream, int, int, Options)}, except that it accepts a {@link
   * ByteBuffer} in place of an {@link InputStream}.
   */
  public func decode(buffer: Array<UInt8>, requestedWidth: Int64, requestedHeight: Int64, options: GlideOptions): Option<GlideResource<PixelMapDrawable>> {
    return decode(
        ByteArrayReader(buffer, DefaultImageHeaderParser()),
        requestedWidth,
        requestedHeight,
        options,
        EMPTY_CALLBACKS);
  }

  public func decodeDrawable(buffer: Array<UInt8>, requestedWidth: Int64, requestedHeight: Int64, options: GlideOptions): Option<PixelMapDrawable> {
    return decodeDrawable(
        ByteArrayReader(buffer, DefaultImageHeaderParser()),
        requestedWidth,
        requestedHeight,
        options,
        EMPTY_CALLBACKS);
  }

  public func decodePixelMap(buffer: Array<UInt8>, requestedWidth: Int64, requestedHeight: Int64, options: GlideOptions): Option<PixelMap> {
    return decodePixelMap(
        ByteArrayReader(buffer, DefaultImageHeaderParser()),
        requestedWidth,
        requestedHeight,
        options,
        EMPTY_CALLBACKS);
  }

    // TODO 暂时不用解码inputstream
    // public func decode(
    //   inputStream: InputStream,
    //   requestedWidth: Int64,
    //   requestedHeight: Int64,
    //   options: GlideOptions,
    //   callbacks: DecodeCallbacks): GlideResource<Bitmap> {
    //     return decode(
    //         InputStreamImageReader(is, parsers, byteArrayPool),
    //         requestedWidth,
    //         requestedHeight,
    //         options,
    //         callbacks);
    // }

    private func decode(
      imageReader: ImageReader,
      requestedWidth: Int64,
        requestedHeight: Int64,
        options: GlideOptions,
        callbacks: DecodeCallbacks): Option<GlideResource<PixelMapDrawable>> {

    // DecodeFormat decodeFormat = options.get(DECODE_FORMAT);
    // PreferredColorSpace preferredColorSpace = options.get(PREFERRED_COLOR_SPACE);
    let downsampleStrategy: DownsampleStrategy = options.get(DownsampleStrategy.OPTION);
    // boolean fixBitmapToRequestedDimensions = options.get(FIX_BITMAP_SIZE_TO_REQUESTED_DIMENSIONS);
    // boolean isHardwareConfigAllowed =
    //     options.get(ALLOW_HARDWARE_CONFIG) != null && options.get(ALLOW_HARDWARE_CONFIG);

      let result: Option<PixelMap> =
          decodeFromWrappedStreams(
              imageReader,
              downsampleStrategy,
              requestedWidth,
              requestedHeight,
              callbacks);

    // return PixelMapResource.obtain(result.getOrThrow());

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
      imageType: ImageType,
      imageReader: ImageReader,
      decodeCallbacks: DecodeCallbacks,
      downsampleStrategy: DownsampleStrategy,
      sourceWidth: Int64,
      sourceHeight: Int64,
      targetWidth: Int64,
      //targetHeight: Int64): Float64 {
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

    AppLog.error("exactScaleFactor: ${exactScaleFactor}")

    if (exactScaleFactor <= 0.0) {
    //   throw IllegalArgumentException(
    //       "Cannot scale with factor: "
    //           + exactScaleFactor
    //           + " from: "
    //           + downsampleStrategy
    //           + ", source: ["
    //           + sourceWidth
    //           + "x"
    //           + sourceHeight
    //           + "]"
    //           + ", target: ["
    //           + targetWidth
    //           + "x"
    //           + targetHeight
    //           + "]");
        throw GlideException("Cannot scale with factor")
    }else if(exactScaleFactor > 1.0){
            exactScaleFactor = 1.0
    }

    // 采样大小舍入规则
    let rounding: SampleSizeRounding =
        downsampleStrategy.getSampleSizeRounding(
            orientedSourceWidth, orientedSourceHeight, targetWidth, targetHeight);
    // if (rounding == null) {
    //   throw new IllegalArgumentException("Cannot round with null rounding");
    // }

    let outWidth: Int32 = Int32(round(exactScaleFactor * Float64(orientedSourceWidth)));
    let outHeight: Int32 = Int32(round(exactScaleFactor * Float64(orientedSourceHeight)));
    return (outWidth, outHeight)

//    let widthScaleFactor: Int64 = orientedSourceWidth / outWidth;
//    let heightScaleFactor: Int64 = orientedSourceHeight / outHeight;
//    AppLog.error("outWidth outHeight widthScaleFactor heightScaleFactor: ${outWidth} ${outHeight} ${widthScaleFactor} ${heightScaleFactor}")
//    // TODO: This isn't really right for both CenterOutside and CenterInside. Consider allowing
//    // DownsampleStrategy to pick, or trying to do something more sophisticated like picking the
//    // scale factor that leads to an exact match.
//
//    // 根据SampleSizeRounding选取合适的缩放因子
//    let scaleFactor: Int64 =
//        if(match(rounding) {
//            case SampleSizeRounding.MEMORY => true
//            case _ => false
//        }) {
//            max(widthScaleFactor, heightScaleFactor)
//        } else {
//            min(widthScaleFactor, heightScaleFactor)
//        }
//
//    var powerOfTwoSampleSize: Int64 = 1;
//    // inSampleSize  缩小比例  2的幂次Integer.highestOneBit倍
//    // BitmapFactory does not support downsampling wbmp files on platforms <= M. See b/27305903.
//    // if (Build.VERSION.SDK_INT <= 23
//    //     && NO_DOWNSAMPLE_PRE_N_MIME_TYPES.contains(options.outMimeType)) {
//    //   powerOfTwoSampleSize = 1;
//    // } else {
//      powerOfTwoSampleSize = max(1, Integer.highestOneBit(scaleFactor));
//      if (match(rounding) {
//        case SampleSizeRounding.MEMORY => true
//        case _ => false
//      } && powerOfTwoSampleSize < Int64(1.0 / exactScaleFactor)) {
//        powerOfTwoSampleSize = powerOfTwoSampleSize << 1;
//      }
//    // }
//
//
//    // inSampleSize
//    // options.inSampleSize = powerOfTwoSampleSize;
//    // var powerOfTwoWidth: Int64;
//    // var powerOfTwoHeight: Int64;
//
//    let powerOfTwoWidth = orientedSourceWidth / powerOfTwoSampleSize;
//    let powerOfTwoHeight = orientedSourceHeight / powerOfTwoSampleSize;
//    // Here we mimic framework logic for determining how inSampleSize division is rounded on various
//    // versions of Android. The logic here has been tested on emulators for Android versions 15-26.
//    // PNG - Always uses floor
//    // JPEG - Always uses ceiling
//    // Webp - Prior to N, always uses floor. At and after N, always uses round.
//
//    // if (imageType == ImageType.JPEG) {
//    //   // libjpegturbo can downsample up to a sample size of 8. libjpegturbo uses ceiling to round.
//    //   // After libjpegturbo's native rounding, skia does a secondary scale using floor
//    //   // (integer division). Here we replicate that logic.
//    //   int nativeScaling = Math.min(powerOfTwoSampleSize, 8);
//    //   powerOfTwoWidth = (int) Math.ceil(orientedSourceWidth / (float) nativeScaling);
//    //   powerOfTwoHeight = (int) Math.ceil(orientedSourceHeight / (float) nativeScaling);
//    //   int secondaryScaling = powerOfTwoSampleSize / 8;
//    //   if (secondaryScaling > 0) {
//    //     powerOfTwoWidth = powerOfTwoWidth / secondaryScaling;
//    //     powerOfTwoHeight = powerOfTwoHeight / secondaryScaling;
//    //   }
//    // } else if (imageType == ImageType.PNG || imageType == ImageType.PNG_A) {
//    //   powerOfTwoWidth = (int) Math.floor(orientedSourceWidth / (float) powerOfTwoSampleSize);
//    //   powerOfTwoHeight = (int) Math.floor(orientedSourceHeight / (float) powerOfTwoSampleSize);
//    // } else if (imageType.isWebp()) {
//    //   if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
//    //     powerOfTwoWidth = Math.round(orientedSourceWidth / (float) powerOfTwoSampleSize);
//    //     powerOfTwoHeight = Math.round(orientedSourceHeight / (float) powerOfTwoSampleSize);
//    //   } else {
//    //     powerOfTwoWidth = (int) Math.floor(orientedSourceWidth / (float) powerOfTwoSampleSize);
//    //     powerOfTwoHeight = (int) Math.floor(orientedSourceHeight / (float) powerOfTwoSampleSize);
//    //   }
//    // } else if (orientedSourceWidth % powerOfTwoSampleSize != 0
//    //     || orientedSourceHeight % powerOfTwoSampleSize != 0) {
//    //   // If we're not confident the image is in one of our types, fall back to checking the
//    //   // dimensions again. inJustDecodeBounds decodes do obey inSampleSize.
//    //   int[] dimensions = getDimensions(imageReader, options, decodeCallbacks, bitmapPool);
//    //   // Power of two downsampling in BitmapFactory uses a variety of random factors to determine
//    //   // rounding that we can't reliably replicate for all image formats. Use ceiling here to make
//    //   // sure that we at least provide a Bitmap that's large enough to fit the content we're going
//    //   // to load.
//    //   powerOfTwoWidth = dimensions[0];
//    //   powerOfTwoHeight = dimensions[1];
//    // } else {
//    //   powerOfTwoWidth = orientedSourceWidth / powerOfTwoSampleSize;
//    //   powerOfTwoHeight = orientedSourceHeight / powerOfTwoSampleSize;
//    // }
//
//    // 计算采样后的缩放因子
//    let adjustedScaleFactor: Float64 =
//        downsampleStrategy.getScaleFactor(
//            powerOfTwoWidth, powerOfTwoHeight, targetWidth, targetHeight);
//
//    // inTargetDensity  目标像素密度 表示要缩放到的目标图像像素密度值
////                           该值需要结合 inScaled 值使用
////                           如果同时设置了 inScaled = true , 和 inDensity 像素密度值 , 在图像返回时 ,
////                           会自动将图像按照 inDensity 向 inTargetDensity 缩放
//    //      inDensity        像素密度
//    // Density scaling is only supported if inBitmap is null prior to KitKat. Avoid setting
//    // densities here so we calculate the final Bitmap size correctly.
//    // if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
//    //   options.inTargetDensity = adjustTargetDensityForError(adjustedScaleFactor);
//    //   options.inDensity = getDensityMultiplier(adjustedScaleFactor);
//    // }
//    // if (isScaling(options)) {
//    //   options.inScaled = true;
//    // } else {
//    //   options.inDensity = options.inTargetDensity = 0;
//    // }
//    return adjustedScaleFactor
  }

  private func decodeDrawable(
      imageReader: ImageReader,
      requestedWidth: Int64,
        requestedHeight: Int64,
        options: GlideOptions,
        callbacks: DecodeCallbacks): Option<PixelMapDrawable> {

    let result = decodePixelMap(imageReader, requestedWidth, requestedHeight, options, callbacks)

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
        options: GlideOptions,
        callbacks: DecodeCallbacks): Option<PixelMap> {

    // DecodeFormat decodeFormat = options.get(DECODE_FORMAT);
    // PreferredColorSpace preferredColorSpace = options.get(PREFERRED_COLOR_SPACE);
    let downsampleStrategy: DownsampleStrategy = options.get(DownsampleStrategy.OPTION);
    // boolean fixBitmapToRequestedDimensions = options.get(FIX_BITMAP_SIZE_TO_REQUESTED_DIMENSIONS);
    // boolean isHardwareConfigAllowed =
    //     options.get(ALLOW_HARDWARE_CONFIG) != null && options.get(ALLOW_HARDWARE_CONFIG);

    let result: Option<PixelMap> =
        decodeFromWrappedStreams(
            imageReader,
            downsampleStrategy,
            requestedWidth,
            requestedHeight,
            callbacks);

    // return PixelMapResource.obtain(result.getOrThrow());
    return result
      
  }

  private func calculateConfig(
      imageReader: ImageReader,
    //   format: DecodeFormat,
    //   boolean isHardwareConfigAllowed,
    //   boolean isExifOrientationRequired,
    //   BitmapFactory.Options optionsWithScaling,
      targetWidth: Int64,
      targetHeight: Int64): Unit {

    // // Changing configs can cause skewing on 4.1, see issue #128.
    // if (format == DecodeFormat.PREFER_ARGB_8888
    //     || Build.VERSION.SDK_INT == Build.VERSION_CODES.JELLY_BEAN) {
    //   optionsWithScaling.inPreferredConfig = Bitmap.Config.ARGB_8888;
    //   return;
    // }

    // boolean hasAlpha = false;
    // try {
    //   hasAlpha = imageReader.getImageType().hasAlpha();
    // } catch (IOException e) {
    //   if (Log.isLoggable(TAG, Log.DEBUG)) {
    //     Log.d(
    //         TAG,
    //         "Cannot determine whether the image has alpha or not from header"
    //             + ", format "
    //             + format,
    //         e);
    //   }
    // }

    // optionsWithScaling.inPreferredConfig =
    //     hasAlpha ? Bitmap.Config.ARGB_8888 : Bitmap.Config.RGB_565;
    // if (optionsWithScaling.inPreferredConfig == Config.RGB_565) {
    //   optionsWithScaling.inDither = true;
    // }
  }

  private func decodeFromWrappedStreams(
      imageReader: ImageReader,
      downsampleStrategy: DownsampleStrategy,
      requestedWidth: Int64,
      requestedHeight: Int64,
      callbacks: DecodeCallbacks): Option<PixelMap> {

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

    let orientation: Int64 = imageReader.getImageOrientation();

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

    let imageType: ImageType = imageReader.getImageType();

    //let scaling = calculateScaling(
    let (finalWidth, finalHeight) = calculateScaling(
        imageType,
        imageReader,
        callbacks,
        downsampleStrategy,
        sourceWidth,
        sourceHeight,
        targetWidth,
        targetHeight);

    
    //let finalWidth = Int32(Float64(sourceWidth) * scaling)
    //let finalHeight = Int32(Float64(sourceHeight) * scaling)

    AppLog.error("downsample decode : ${sourceWidth} -- ${sourceHeight}")
    AppLog.error("downsample decode : ${targetWidth} -- ${targetHeight}")
    //AppLog.error("downsample decode : ${scaling}")
    AppLog.error("downsample decode : ${finalWidth} -- ${finalHeight}")


    // calculateConfig(
    //     imageReader,
    //     // decodeFormat,
    //     // isHardwareConfigAllowed,
    //     // isExifOrientationRequired,
    //     targetWidth,
    //     targetHeight);

    // boolean isKitKatOrGreater = Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT;
    // Prior to KitKat, the inBitmap size must exactly match the size of the bitmap we're decoding.
    // if ((options.inSampleSize == 1 || isKitKatOrGreater) && shouldUsePool(imageType)) {
    //   int expectedWidth;
    //   int expectedHeight;
    //   if (sourceWidth >= 0
    //       && sourceHeight >= 0
    //       && fixBitmapToRequestedDimensions
    //       && isKitKatOrGreater) {
    //     expectedWidth = targetWidth;
    //     expectedHeight = targetHeight;
    //   } else {
    //     float densityMultiplier =
    //         isScaling(options) ? (float) options.inTargetDensity / options.inDensity : 1f;
    //     int sampleSize = options.inSampleSize;
    //     int downsampledWidth = (int) Math.ceil(sourceWidth / (float) sampleSize);
    //     int downsampledHeight = (int) Math.ceil(sourceHeight / (float) sampleSize);
    //     expectedWidth = Math.round(downsampledWidth * densityMultiplier);
    //     expectedHeight = Math.round(downsampledHeight * densityMultiplier);

    //     // if (Log.isLoggable(TAG, Log.VERBOSE)) {
    //     //   Log.v(
    //     //       TAG,
    //     //       "Calculated target ["
    //     //           + expectedWidth
    //     //           + "x"
    //     //           + expectedHeight
    //     //           + "] for source"
    //     //           + " ["
    //     //           + sourceWidth
    //     //           + "x"
    //     //           + sourceHeight
    //     //           + "]"
    //     //           + ", sampleSize: "
    //     //           + sampleSize
    //     //           + ", targetDensity: "
    //     //           + options.inTargetDensity
    //     //           + ", density: "
    //     //           + options.inDensity
    //     //           + ", density multiplier: "
    //     //           + densityMultiplier);
    //     // }
    //   }
    //   // If this isn't an image, or BitmapFactory was unable to parse the size, width and height
    //   // will be -1 here.
    //   if (expectedWidth > 0 && expectedHeight > 0) {
    //     setInBitmap(options, bitmapPool, expectedWidth, expectedHeight);
    //   }
    // }

    // 色彩空间
    // if (preferredColorSpace != null) {
    //   if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
    //     boolean isP3Eligible =
    //         preferredColorSpace == PreferredColorSpace.DISPLAY_P3
    //             && options.outColorSpace != null
    //             && options.outColorSpace.isWideGamut();
    //     options.inPreferredColorSpace =
    //         ColorSpace.get(isP3Eligible ? ColorSpace.Named.DISPLAY_P3 : ColorSpace.Named.SRGB);
    //   } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
    //     options.inPreferredColorSpace = ColorSpace.get(ColorSpace.Named.SRGB);
    //   }
    // }

    // decode
    // Bitmap downsampled = decodeStream(imageReader, options, callbacks, bitmapPool);
    // callbacks.onDecodeComplete(bitmapPool, downsampled);

    let downsampled: Option<PixelMap> = imageReader.decodePixelMap(finalWidth, finalHeight)
    AppLog.error("downsample decode : ${finalWidth} -- ${finalHeight}")
    // if (Log.isLoggable(TAG, Log.VERBOSE)) {
    //   logDecode(
    //       sourceWidth,
    //       sourceHeight,
    //       sourceMimeType,
    //       options,
    //       downsampled,
    //       requestedWidth,
    //       requestedHeight,
    //       startTime);
    // }

    if(match(downsampled) {
        case Some(x) => false
        case _ => true
    }) {
        return None
    }

    // calculateScaling 缩放图片适合显示区域  scaling 缩放倍数

    // TODO 缩放图片resize


    // 旋转
    // Bitmap rotated = null;
    // if (downsampled != null) {
    //   // If we scaled, the Bitmap density will be our inTargetDensity. Here we correct it back to
    //   // the expected density dpi.
    //   downsampled.setDensity(displayMetrics.densityDpi);

    //   rotated = TransformationUtils.rotateImageExif(bitmapPool, downsampled, orientation);
    //   if (!downsampled.equals(rotated)) {
    //     bitmapPool.put(downsampled);
    //   }
    // }

    // return rotated;
    return downsampled
  }

}