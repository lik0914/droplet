/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2023-2024. All rights resvered.
 */
 
package glide

from ohos import image.*

/**
* 图片工具类
*/
public class ImageUtils {

    public static let ImageFormatBMP: Int64 = 1
    public static let ImageFormatJPEG: Int64 = 2
    public static let ImageFormatPNG: Int64 = 3
    public static let ImageFormatWEBP: Int64 = 4
    public static let ImageFormatGIF: Int64 = 5
    public static let ImageFormatSVG: Int64 = 6
    public static let ImageFormatRAW: Int64 = 7
    public static let ImageFormatUNKNOWN: Int64 = -1

    /**
     * 根据buf最前面的字符序列判断图片类型
     */
    static public func getImageType(data:Array<UInt8>): Int64 {
		if (data[0]==0x42 && data[1]==0x4D){  // "BM"
            //AppLog.error("BMP")
			return ImageFormatBMP
        }else if(data[0] == 0xFF && data[1] == 0xD8 ){  //"FFD8"
            //AppLog.error("JPG")
			return ImageFormatJPEG
        }else if(data[0] == 0x89 && data[1] == 0x50 &&
            data[2] == 0x4E && data[3] == 0x47 &&
            data[4] == 0x0D && data[5] == 0x0A &&
            data[6] == 0x1A && data[7] == 0x0A ){  //"89 50 4E 47 0D 0A 1A 0A"
            //AppLog.error("PNG")
			return ImageFormatPNG
        }else if(data[0] == 0x52 && data[1] == 0x49 &&
             data[2] == 0x46 && data[3] == 0x46 && 
             data[8] == 0x57 && data[9] == 0x45 &&
             data[10] == 0x42 && data[11] == 0x50  ){ //"52 49 46 46 X X X X 57 45 42 50"
             //AppLog.error("WEBP")
			return ImageFormatWEBP
        }else if(data[0] == 71 && data[1] == 73 && data[2] == 70 ){  //"GIF"
            //AppLog.error("GIF")
			return ImageFormatGIF
        }else if(data[0] == 0x3c && data[1] == 0x73 && data[2] == 0x76 && data[3] == 0x67 ){ //3C 73 76 67
            //AppLog.error("SVG")
			return ImageFormatSVG
        }
        return ImageFormatUNKNOWN
    }

    public static func arrToPixelMap(arr: Array<UInt8>, width: Int32, height: Int32): PixelMap {
        let size: Size = Size(width: width, height: height)
        //适配
        //let opts: InitializationOptions = InitializationOptions(size, pixelFormat: PixelMapFormat.RGBA_8888, editable: true)
        //let opts: InitializationOptions = InitializationOptions(size: size, pixelFormat: PixelMapFormat.RGBA_8888, editable: true)
        // let bitmap: PixelMap = PixelMap(firstFrame.getData32(), UInt32(firstFrame.len), opts)
        //适配
        //let bitmap: PixelMap = PixelMap(opts)
        //bitmap.writeBufferToPixels(arr)
        let color:Array<UInt8> = Array<UInt8>(arr.size,item:0)
        let bitmap:PixelMap = createPixelMap(color,InitializationOptions(size: size, pixelFormat: PixelMapFormat.RGBA_8888, editable: true))
        bitmap.writeBufferToPixels(arr)
        return bitmap
    }

    //public static func arrToPixelMap(arr: Array<UInt32>, width: Int32, height: Int32): PixelMap {
    //    let size: Size = Size(width: width, height: height)
    //    let opts: InitializationOptions = InitializationOptions(size, pixelFormat: PixelMapFormat.RGBA_8888, editable: true)
    //    let bitmap: PixelMap = PixelMap(arr, UInt32(arr.size), opts)
    //    return bitmap
    //}

    public static func decodePixelMap(bytes: Array<UInt8>, targetWidth: Int64, targetHeight: Int64): PixelMap {
        var size: Size = Size(width: Int32(targetWidth), height: Int32(targetHeight))
        //适配
        //var sourceOptions: SourceOptions = SourceOptions(size)
        //let imageSource: ImageSource= ImageAbility.createImageSource(bytes, sourceOptions)
        var sourceOptions: SourceOptions = SourceOptions(sourceSize: size)
        let imageSource: ImageSource= image.createImageSource(bytes, sourceOptions)

        let info: ImageInfo = imageSource.getImageInfo()

        let desiredSize: Size = size

        let regionSize: Size = Size(width: info.size.width, height: info.size.height)
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

        //return imageSource.createPixelMap(Some(decodingOptions))
        return imageSource.createPixelMap(options: decodingOptions)
    }

    public static func decodePixelMap(path: String, targetWidth: Int64, targetHeight: Int64): PixelMap {
        var size: Size = Size(width: Int32(targetWidth), height: Int32(targetHeight))
        //适配
        //var sourceOptions: SourceOptions = SourceOptions(size)
        //let imageSource: ImageSource= ImageAbility.createImageSource(path, sourceOptions)
        var sourceOptions: SourceOptions = SourceOptions(sourceSize: size)
        let imageSource: ImageSource= image.createImageSource(path, sourceOptions)

        let info: ImageInfo = imageSource.getImageInfo()

        let desiredSize: Size = size

        let regionSize: Size = Size(width: info.size.width, height: info.size.height)
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

        //return imageSource.createPixelMap(Some(decodingOptions))
        return imageSource.createPixelMap(options: decodingOptions)
    }
}
