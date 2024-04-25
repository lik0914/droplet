package glide.load.resource.gif

from ohos import image.*
import glide.load.resource.*
import glide.load.*
import glide.engine.cache.*

import glide.util.utils.*

/**
 * Decodes {@link Bitmap}s from {@link GifDecoder}s representing a particular frame of a particular
 * GIF image.
 */
public class GifFrameResourceDecoder <: ResourceDecoder<GifDecoder, PixelMap> {

  public init() {
  }

  public func handles(source: GifDecoder, options: GlideOptions): Bool {
    return true;
  }

  public func decode(source: GifDecoder, width: Int64, height: Int64, options: GlideOptions): PixelMap {
    let (ret, firstFrame) = source.getNextFrame();
    //let bitmap: PixelMap = ImageUtils.arrToPixelMap(firstFrame.getData(), Int32(firstFrame.width), Int32(firstFrame.height))
    //return bitmap;
    return firstFrame
  }

  public func setTransformation(transformation: Option<AnyTransformation>): Unit {}

}
