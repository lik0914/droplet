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

public class GifFrameResourceDecoder {
  public init() {
  }



   public func decode(source: GifDecoder): PixelMap {
    let (ret, firstFrame) = source.getNextFrame();
    return firstFrame
  }


}
