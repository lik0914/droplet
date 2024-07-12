/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2023-2024. All rights resvered.
 */
 
package glide


// public interface ResourceDecoder<T, Z> {
//     func handles(data: T, options: GlideOptions): Bool

//     func decode(source: T, width: Int64, height: Int64, options: GlideOptions): Z

//     func setTransformation(transformation: Option<AnyTransformation>): Unit
// }

public class PixelMapDrawableResourceParser <: ResourceDecoder<Array<UInt8>, Drawable> {

    public static let SIZE_ORIGINAL: Int64 = -0x7FFFFFFFFFFFFFFF

    public func setTransformation(transformation: Option<AnyTransformation>): Unit {}

    public func handles(data: Array<UInt8>, options: GlideOptions): Bool {
        return true
    }

    public func decode(source: Array<UInt8>, width: Int64, height: Int64, options: GlideOptions): Drawable {
        let finalWidth: Int32 = Int32(UInt16(source[0]) << 8 | UInt16(source[1]))
        let finalHeight: Int32 = Int32(UInt16(source[2]) << 8 | UInt16(source[3]))
        let pixelMap: PixelMap = ImageUtils.arrToPixelMap(source[4..source.size], finalWidth, finalHeight)
        return PixelMapDrawable(pixelMap)
    }

}

public class PixelMapDrawableResourceDecoder <: ResourceDecoder<Array<UInt8>, Drawable> {

    private let downsampler: Downsampler = Downsampler()

    public func setTransformation(transformation: Option<AnyTransformation>): Unit {}

    public func handles(data: Array<UInt8>, options: GlideOptions): Bool {
        AppLog.error("PixelMapDrawableResourceDecoder handles : ${data.size}")
        return !isGif(data)
    }

    public func decode(source: Array<UInt8>, width: Int64, height: Int64, options: GlideOptions): Drawable {
        decodeImage(source, width, height, options).getOrThrow()
    }

    private func isGif(data: Array<UInt8>): Bool {
        // let headerParser:GifHeaderParser = GifHeaderParser();
        // headerParser.setData(data);
        // let header:GifHeader = headerParser.parseHeader();
        // return header.getFrameCount() > 0
        AppLog.error("PixelMapDrawableResourceDecoder isGif : ${data.size}")
        return ImageUtils.getImageType(data) == ImageUtils.ImageFormatGIF
    }

    private func decodeImage(buffer: Array<UInt8>, requestedWidth: Int64, requestedHeight: Int64, options: GlideOptions): Option<PixelMapDrawable> {
        AppLog.error("helper decodeImage: ${requestedWidth} -- ${requestedHeight}")
        return downsampler.decodeDrawable(buffer, requestedWidth, requestedHeight, options)
    }
}

public class GifDrawableResourceDecoder <: ResourceDecoder<Array<UInt8>, Drawable> {

    private var transformation: Option<AnyTransformation> = None

    public func setTransformation(transformation: Option<AnyTransformation>): Unit {
        this.transformation = transformation
    }

    public func handles(data: Array<UInt8>, options: GlideOptions): Bool {
        AppLog.error("GifDrawableResourceDecoder handles : ${data.size}")
        return isGif(data)
    }

    public func decode(source: Array<UInt8>, width: Int64, height: Int64, options: GlideOptions): Drawable {
        decodeImageGIF(source, width, height, options, this.transformation).getOrThrow()
    }

    private func isGif(data: Array<UInt8>): Bool {
        AppLog.error("GifDrawableResourceDecoder isGif : ${data.size}")
        return ImageUtils.getImageType(data) == ImageUtils.ImageFormatGIF
    }

    private func decodeImageGIF(buffer: Array<UInt8>, requestedWidth: Int64, requestedHeight: Int64, options: GlideOptions, transformation: Option<AnyTransformation>): Option<GifDrawable> {
        AppLog.error("decodeImageGIF : ${buffer.size}")
        //let headerParser: GifHeaderParser = GifHeaderParser();
        //headerParser.setData(buffer);
        //let header: GifHeader = headerParser.parseHeader();
        //if(header.getFrameCount() <= 0) {
        //return None
        //}

        //let provider = GifBitmapProvider()
        //let decoder: GifDecoder = StandardGifDecoder(provider);
        let decoder: GifDecoder = StandardGifDecoder(Int32(requestedWidth), Int32(requestedHeight), buffer)
        //decoder.setData(header, buffer);

        decoder.advance();
        let (ret1,firstFrame) = decoder.getNextFrame();
        AppLog.error("getnextframe : ${ret1}")
        //let data: Array<UInt32> = firstFrame.getData32()
        //AppLog.error("getnextframe size : ${data.size} ${firstFrame.width} ${firstFrame.height}")
        //let pixelMap: PixelMap = ImageUtils.arrToPixelMap(data, Int32(firstFrame.width), Int32(firstFrame.height))
        return Some(GifDrawable(decoder, requestedWidth, requestedHeight, firstFrame, transformation))
    }
}

public class PixelMapResourceDecoder <: ResourceDecoder<Array<UInt8>, PixelMap> {
    private let downsampler: Downsampler = Downsampler()

    public func setTransformation(transformation: Option<AnyTransformation>): Unit {}

    public func handles(data: Array<UInt8>, options: GlideOptions): Bool {
        return !isGif(data)
    }

    public func decode(source: Array<UInt8>, width: Int64, height: Int64, options: GlideOptions): PixelMap {
        decodeImage(source, width, height, options).getOrThrow()
    }

    private func isGif(data: Array<UInt8>): Bool {
        AppLog.error("PixelMapResourceDecoder isGif : ${data.size}")
        return ImageUtils.getImageType(data) == ImageUtils.ImageFormatGIF
    }

    private func decodeImage(buffer: Array<UInt8>, requestedWidth: Int64, requestedHeight: Int64, options: GlideOptions): Option<PixelMap> {
        AppLog.error("helper decodeImage: ${requestedWidth} -- ${requestedHeight}")
        return downsampler.decodePixelMap(buffer, requestedWidth, requestedHeight, options)
    }

}

