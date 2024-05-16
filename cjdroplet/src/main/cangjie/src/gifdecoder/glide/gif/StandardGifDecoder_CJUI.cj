package gifdecoder.glide.gif

public class StandardGifDecoder <: GifDecoder {

  /** The "Netscape" loop count which means loop forever. */
  public static let NETSCAPE_LOOP_COUNT_FOREVER :Int32 = 0
  /** Indicates that this header has no "Netscape" loop count. */
  public static let NETSCAPE_LOOP_COUNT_DOES_NOT_EXIST:Int32 = -1

  private static let INITIAL_FRAME_POINTER:Int32 = -1

  private var imageSource: ImageSource

  private var currentFrameIndex: Int32 = INITIAL_FRAME_POINTER
  private var frameCount: Int32 = 0

  private var width: Int32 = 0
  private var height: Int32 = 0
  private var density: Int32 = 0

  private var sampleSize: Int32 = 0
  private var downsampledWidth: Int32 = 0
  private var downsampledHeight: Int32 = 0

  private var delayTimeList: Array<UInt32>
  private var loopCount: Int32 = NETSCAPE_LOOP_COUNT_DOES_NOT_EXIST

  // Public API.
    public init(width: Int32, height: Int32, data: Array<UInt8>){
        this.imageSource = createImageSource(data)
        this.frameCount = Int32(this.imageSource.getFrameCount())
        if (this.frameCount > 0){
            let info: ImageInfo = this.imageSource.getImageInfo()
            this.width = info.size.width
            this.height = info.size.height
            this.density = info.density
        }
        this.delayTimeList = this.imageSource.getDelayTimeList()

        this.calcSampleSize(width, height)
        this.setData(data)
    }


  public func getWidth():Int32 {
    return width;
  }

  
  public func getHeight():Int32 {
    return height;
  }

  public func getData():ByteBuffer {
    return ByteBuffer()
  }

  public func getStatus():Int32 {
    return 0
  }

  public func advance() :Unit{
    currentFrameIndex = (currentFrameIndex + 1) % frameCount
  }

  public func getDelay(n:Int32):Int32 {
    return Int32(delayTimeList[Int64(n)])
  }

  public func getNextDelay():Int32 {
    if (frameCount <= 0 || currentFrameIndex < 0) {
      return 0;
    }

    return getDelay(currentFrameIndex);
  }

  public func getFrameCount():Int32 {
    return frameCount;
  }

  public func getCurrentFrameIndex():Int32 {
    return currentFrameIndex
  }

  public func resetFrameIndex():Unit {
    currentFrameIndex = INITIAL_FRAME_POINTER
  }

  public func getLoopCount():Int32 {
    if (loopCount == NETSCAPE_LOOP_COUNT_DOES_NOT_EXIST) {
      return 1;
    }
    return loopCount;
  }

  public func getNetscapeLoopCount():Int32 {
    return loopCount;
  }

  public func getTotalIterationCount():Int32 {
    if (loopCount == NETSCAPE_LOOP_COUNT_DOES_NOT_EXIST) {
      return 1;
    }
    if (loopCount == NETSCAPE_LOOP_COUNT_FOREVER) {
      return TOTAL_ITERATION_COUNT_FOREVER;
    }
    return loopCount + 1;
  }

  public func getByteSize():Int32 {
    return 0
  }

  public func getNextFrame():(Bool,PixelMap)  {
    let option = DecodingOptions(
        sampleSize: 1,
        rotate: 0,
        editable: true,
        desiredSize: Size(height: this.downsampledHeight, width: this.downsampledWidth),
        desiredRegion: Region(Size(height: this.height, width: this.width), 0, 0),
        desiredPixelFormat: PixelMapFormat.RGBA_8888,
        index: UInt32(this.currentFrameIndex)
    )
    let res: PixelMap = this.imageSource.createPixelMap(options: option)
    return (true, res)
  }


  public func clear():Unit {
    this.imageSource.Release()
  }

  public func setData(data:Array<UInt8>):Unit {
    this.imageSource = image.createImageSource(data)
    let info: ImageInfo = this.imageSource.getImageInfo(index: UInt32(0))
    this.width = info.size.width
    this.height = info.size.height
    this.density = info.density
    this.frameCount = Int32(this.imageSource.getFrameCount())

    this.delayTimeList = this.imageSource.getDelayTimeList()

    currentFrameIndex = INITIAL_FRAME_POINTER
    this.downsampledWidth = this.width / this.sampleSize
    this.downsampledHeight = this.height / this.sampleSize
  }

    public func calcSampleSize(targetWidth: Int32, targetHeight: Int32): Unit {
        let exactSampleSize: Int32 = math.min(getHeight() / targetHeight, getWidth() / targetWidth)
        let powerOfTwoSampleSize: Int32 = if (exactSampleSize == 0) {
            0
        } else {
            Int32(highestOneBit(Int64(exactSampleSize)))
        }
        let ss: Int32 = math.max(1, powerOfTwoSampleSize)
        this.sampleSize = Int32(highestOneBit(Int64(ss)))
    }

}
