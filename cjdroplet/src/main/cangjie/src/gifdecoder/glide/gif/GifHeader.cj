package gifdecoder.glide.gif

/**
 * A header object containing the number of frames in an animated GIF image as well as basic
 * metadata like width and height that can be used to decode each individual frame of the GIF. Can
 * be shared by one or more {@link com.bumptech.glide.gifdecoder.GifDecoder}s to play the same
 * animated GIF in multiple views.
 *
 */
public class GifHeader {

  /** The "Netscape" loop count which means loop forever. */
  public static let NETSCAPE_LOOP_COUNT_FOREVER :Int32 = 0
  /** Indicates that this header has no "Netscape" loop count. */
  public static let NETSCAPE_LOOP_COUNT_DOES_NOT_EXIST:Int32 = -1

  var gct:Array<UInt32> = Array<UInt32>()

  var status:Int32 = GifDecoder.STATUS_OK
  var frameCount:Int32 = 0

  var currentFrame:GifFrame = GifFrame()
  var frames: ArrayList<GifFrame>  = ArrayList<GifFrame>()
  /** Logical screen size: Full image width. */
  var width:Int32 =0
  /** Logical screen size: Full image height. */
  var height:Int32=0

  // 1 : global color table flag.
  var gctFlag:Bool = false
  /**
   * Size of Global Color Table.
   * The value is already computed to be a regular number, this field doesn't store the exponent.
   */
  var gctSize:Int32 =0
  /** Background color index into the Global/Local color table. */
  var bgIndex:Int32 =0
  /**
   * Pixel aspect ratio.
   * Factor used to compute an approximation of the aspect ratio of the pixel in the original image.
   */
  var pixelAspect:Int32 = 0
  var bgColor:UInt32 = 0
  var loopCount:Int32 = NETSCAPE_LOOP_COUNT_DOES_NOT_EXIST

  public func getHeight(): Int32 {
    return height;
  }

  public func getWidth():Int32 {
    return width;
  }
  public func setHeight(val:Int32)  {
    height = val
  }

  public func setWidth(val:Int32) {
    width = val
  }
  public func getNumFrames():Int32 {
    return frameCount;
  }

  /**
   * Global status code of GIF data parsing.
   */
  public func getStatus():Int32 {
    return status;
  }
  public func getGctFlag():Bool{
    return gctFlag
  }

  public func getGctSize():Int32{
    return gctSize
  }
  /** Background color index into the Global/Local color table. */
  public func getBgIndex():Int32{
    return bgIndex
  }
  /**
   * Pixel aspect ratio.
   * Factor used to compute an approximation of the aspect ratio of the pixel in the original image.
   */
  public func getPixelAspect():Int32{
    return pixelAspect
  }
  public func getBgColor():UInt32{
    return bgColor
  }
  public func getLoopCount():Int32{
    return loopCount
  }
  public func setLoopCount(val:Int32){
    loopCount = val
  }
  public func getFrameCount():Int32{
    return frameCount
  }
  public func setFrameCount(val:Int32){
    frameCount = val
  }
  public func getCurrentFrame():GifFrame {
    return currentFrame
  }
  public func getFrames(): ArrayList<GifFrame>{
    return frames
  }

}
