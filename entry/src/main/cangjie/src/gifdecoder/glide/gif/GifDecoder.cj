package gifdecoder.glide.gif

from ohos import image.*

 public interface BitmapProvider {
    /**
     * Returns an {@link Bitmap} with exactly the given dimensions and config.
     *
     * @param width  The width in pixels of the desired {@link android.graphics.Bitmap}.
     * @param height The height in pixels of the desired {@link android.graphics.Bitmap}.
     * @param config The {@link android.graphics.Bitmap.Config} of the desired {@link
     *               android.graphics.Bitmap}.
     */
    func obtain(width:Int32,  height:Int32, config:Bitmap_Config):Bitmap

    /**
     * Releases the given Bitmap back to the pool.
     */
    func release(bitmap:Bitmap):Unit

    /**
     * Returns a byte array used for decoding and generating the frame bitmap.
     *
     * @param size the size of the byte array to obtain
     */
    func obtainByteArray(size:Int32):Array<UInt8>

    /**
     * Releases the given byte array back to the pool.
     */
    func release( bytes1:Array<UInt8>):Unit

    /**
     * Returns an int array used for decoding/generating the frame bitmaps.
     */
    func obtainIntArray( size:Int32):Array<UInt32>

    /**
     * Release the given array back to the pool.
     */
    func release(array:Array<UInt32>):Unit
  }


/**
 * Shared interface for GIF decoders.
 */
public abstract  class GifDecoder {

  /** File read status: No errors. */
  public static let STATUS_OK:Int32 = 0
  /** File read status: Error decoding file (may be partially decoded). */
  public static let STATUS_FORMAT_ERROR:Int32 = 1
  /** File read status: Unable to open source. */
  public static let STATUS_OPEN_ERROR:Int32 = 2
  /** Unable to fully decode the current frame. */
  public static let STATUS_PARTIAL_DECODE:Int32 = 3
  /** The total iteration count which means repeat forever. */
  public static let TOTAL_ITERATION_COUNT_FOREVER:Int32 = 0;

  /**
   * An interface that can be used to provide reused {@link android.graphics.Bitmap}s to avoid GCs
   * from constantly allocating {@link android.graphics.Bitmap}s for every frame.
   */

  public func getWidth():Int32

  public func getHeight():Int32

  public func getData():ByteBuffer

  /**
   * Returns the current status of the decoder.
   *
   * <p> Status will update per frame to allow the caller to tell whether or not the current frame
   * was decoded successfully and/or completely. Format and open failures persist across frames.
   * </p>
   */
  public func getStatus():Int32

  /**
   * Move the animation frame counter forward.
   */
  public func advance():Unit

  /**
   * Gets display duration for specified frame.
   *
   * @param n int index of frame.
   * @return delay in milliseconds.
   */
  public func getDelay(n:Int32):Int32;

  /**
   * Gets display duration for the upcoming frame in ms.
   */
  public func getNextDelay():Int32

  /**
   * Gets the number of frames read from file.
   *
   * @return frame count.
   */
  public func getFrameCount():Int32

  /**
   * Gets the current index of the animation frame, or -1 if animation hasn't not yet started.
   *
   * @return frame index.
   */
  public func getCurrentFrameIndex():Int32

  /**
   * Resets the frame pointer to before the 0th frame, as if we'd never used this decoder to
   * decode any frames.
   */
  public func resetFrameIndex():Unit

  /**
   * Gets the "Netscape" loop count, if any. A count of 0 means repeat indefinitely.
   *
   * @deprecated Use {@link #getNetscapeLoopCount()} instead.
   *             This method cannot distinguish whether the loop count is 1 or doesn't exist.
   * @return loop count if one was specified, else 1.
   */
  public func getLoopCount():Int32

  /**
   * Gets the "Netscape" loop count, if any.
   * A count of 0 ({@link GifHeader#NETSCAPE_LOOP_COUNT_FOREVER}) means repeat indefinitely.
   * It must not be a negative value.
   * <br>
   * Use {@link #getTotalIterationCount()}
   * to know how many times the animation sequence should be displayed.
   *
   * @return loop count if one was specified,
   *         else -1 ({@link GifHeader#NETSCAPE_LOOP_COUNT_DOES_NOT_EXIST}).
   */
  public func getNetscapeLoopCount():Int32

  /**
   * Gets the total count
   * which represents how many times the animation sequence should be displayed.
   * A count of 0 ({@link #TOTAL_ITERATION_COUNT_FOREVER}) means repeat indefinitely.
   * It must not be a negative value.
   * <p>
   *     The total count is calculated as follows by using {@link #getNetscapeLoopCount()}.
   *     This behavior is the same as most web browsers.
   *     <table border='1'>
   *         <tr class='tableSubHeadingColor'><th>{@code getNetscapeLoopCount()}</th>
   *             <th>The total count</th></tr>
   *         <tr><td>{@link GifHeader#NETSCAPE_LOOP_COUNT_FOREVER}</td>
   *             <td>{@link #TOTAL_ITERATION_COUNT_FOREVER}</td></tr>
   *         <tr><td>{@link GifHeader#NETSCAPE_LOOP_COUNT_DOES_NOT_EXIST}</td>
   *             <td>{@code 1}</td></tr>
   *         <tr><td>{@code n (n > 0)}</td>
   *             <td>{@code n + 1}</td></tr>
   *     </table>
   * </p>
   *
   * @see <a href="https://bugs.chromium.org/p/chromium/issues/detail?id=592735#c5">Discussion about
   *      the iteration count of animated GIFs (Chromium Issue 592735)</a>
   *
   * @return total iteration count calculated from "Netscape" loop count.
   */
  public func getTotalIterationCount():Int32

  /**
   * Returns an estimated byte size for this decoder based on the data provided to {@link
   * #setData(GifHeader, byte[])}, as well as internal buffers.
   */
  public func getByteSize():Int32

  /**
   * Get the next frame in the animation sequence.
   *
   * @return Bitmap representation of frame.
   */
  
  public func getNextFrame():(Bool, PixelMap)

  /**
   * Reads GIF image from stream.
   *
   * @param is containing GIF file.
   * @return read status code (0 = no errors).
   */
  public func read(ins: File, contentLength:Int32):Int32

  public func clear():Unit

  public func setData(data:Array<UInt8>):Unit

  public func setData(header:GifHeader, data:Array<UInt8>):Unit

  public func setData(header:GifHeader, buffer:ByteBuffer):Unit

  public func setData(header:GifHeader, buffer:ByteBuffer, sampleSize:Int32):Unit;

  /**
   * Reads GIF image from byte array.
   *
   * @param data containing GIF file.
   * @return read status code (0 = no errors).
   */
  public func read(data:Array<UInt8>):Int32


  /**
   * Sets the default {@link android.graphics.Bitmap.Config} to use when decoding frames of a GIF.
   *
   * <p>Valid options are {@link android.graphics.Bitmap.Config#ARGB_8888} and
   * {@link android.graphics.Bitmap.Config#RGB_565}.
   * {@link android.graphics.Bitmap.Config#ARGB_8888} will produce higher quality frames, but will
   * also use 2x the memory of {@link android.graphics.Bitmap.Config#RGB_565}.
   *
   * <p>Defaults to {@link android.graphics.Bitmap.Config#ARGB_8888}
   *
   * <p>This value is not a guarantee. For example if set to
   * {@link android.graphics.Bitmap.Config#RGB_565} and the GIF contains transparent pixels,
   * {@link android.graphics.Bitmap.Config#ARGB_8888} will be used anyway to support the
   * transparency.
   */
  public func setDefaultBitmapConfig(format:Bitmap_Config):Unit
}
