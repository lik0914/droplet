/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2023-2024. All rights resvered.
 */
 
package droplet.droplet


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
