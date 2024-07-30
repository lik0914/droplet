/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2023-2024. All rights resvered.
 */
 
package droplet.droplet


public class PixelMapDrawableResourceParser <: ResourceDecoder<Array<UInt8>, Drawable> {

    public static let SIZE_ORIGINAL: Int64 = -0x7FFFFFFFFFFFFFFF

    public func setTransformation(transformation: Option<AnyTransformation>): Unit {}

    public func handles(data: Array<UInt8>, options: DropletOptions): Bool {
        return true
    }

    public func decode(source: Array<UInt8>, width: Int64, height: Int64, options: DropletOptions): Drawable {
        let finalWidth: Int32 = Int32(UInt16(source[0]) << 8 | UInt16(source[1]))
        let finalHeight: Int32 = Int32(UInt16(source[2]) << 8 | UInt16(source[3]))
        let pixelMap: PixelMap = ImageUtils.arrToPixelMap(source[4..source.size], finalWidth, finalHeight)
        return PixelMapDrawable(pixelMap)
    }

}

public class PixelMapDrawableResourceDecoder <: ResourceDecoder<Array<UInt8>, Drawable> {

    private let downsampler: Downsampler = Downsampler()

    public func setTransformation(transformation: Option<AnyTransformation>): Unit {}

    public func handles(data: Array<UInt8>, options: DropletOptions): Bool {
        return !isGif(data)
    }

    public func decode(source: Array<UInt8>, width: Int64, height: Int64, options: DropletOptions): Drawable {
        decodeImage(source, width, height, options).getOrThrow()
    }

    private func isGif(data: Array<UInt8>): Bool {
        return ImageUtils.getImageType(data) == ImageUtils.ImageFormatGIF
    }

    private func decodeImage(buffer: Array<UInt8>, requestedWidth: Int64, requestedHeight: Int64, options: DropletOptions): Option<PixelMapDrawable> {
        return downsampler.decodeDrawable(buffer, requestedWidth, requestedHeight, options)
    }
}

public class GifDrawableResourceDecoder <: ResourceDecoder<Array<UInt8>, Drawable> {

    private var transformation: Option<AnyTransformation> = None

    public func setTransformation(transformation: Option<AnyTransformation>): Unit {
        this.transformation = transformation
    }

    public func handles(data: Array<UInt8>, options: DropletOptions): Bool {
        return isGif(data)
    }

    public func decode(source: Array<UInt8>, width: Int64, height: Int64, options: DropletOptions): Drawable {
        decodeImageGIF(source, width, height, options, this.transformation).getOrThrow()
    }

    private func isGif(data: Array<UInt8>): Bool {
        return ImageUtils.getImageType(data) == ImageUtils.ImageFormatGIF
    }

    private func decodeImageGIF(buffer: Array<UInt8>, requestedWidth: Int64, requestedHeight: Int64, options: DropletOptions, transformation: Option<AnyTransformation>): Option<GifDrawable> {
        let decoder: GifDecoder = StandardGifDecoder(Int32(requestedWidth), Int32(requestedHeight), buffer)
        decoder.advance();
        let (ret1,firstFrame) = decoder.getNextFrame();
        return Some(GifDrawable(decoder, requestedWidth, requestedHeight, firstFrame, transformation))
    }
}

public class PixelMapResourceDecoder <: ResourceDecoder<Array<UInt8>, PixelMap> {
    private let downsampler: Downsampler = Downsampler()

    public func setTransformation(transformation: Option<AnyTransformation>): Unit {}

    public func handles(data: Array<UInt8>, options: DropletOptions): Bool {
        return !isGif(data)
    }

    public func decode(source: Array<UInt8>, width: Int64, height: Int64, options: DropletOptions): PixelMap {
        decodeImage(source, width, height, options).getOrThrow()
    }

    private func isGif(data: Array<UInt8>): Bool {
        return ImageUtils.getImageType(data) == ImageUtils.ImageFormatGIF
    }

    private func decodeImage(buffer: Array<UInt8>, requestedWidth: Int64, requestedHeight: Int64, options: DropletOptions): Option<PixelMap> {
        return downsampler.decodePixelMap(buffer, requestedWidth, requestedHeight, options)
    }

}

