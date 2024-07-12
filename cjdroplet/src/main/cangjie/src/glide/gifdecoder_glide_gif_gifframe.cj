/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2023-2024. All rights resvered.
 */
 
package glide

/**
 * Inner model class housing metadata for each frame.
 *
 */
public class GifFrame {
  /**
   * GIF Disposal Method meaning take no action.
   * <p><b>GIF89a</b>: <i>No disposal specified.
   * The decoder is not required to take any action.</i></p>
   */
  public static let DISPOSAL_UNSPECIFIED:Int32 = 0
  /**
   * GIF Disposal Method meaning leave canvas from previous frame.
   * <p><b>GIF89a</b>: <i>Do not dispose.
   * The graphic is to be left in place.</i></p>
   */
  public static let DISPOSAL_NONE:Int32 = 1
  /**
   * GIF Disposal Method meaning clear canvas to background color.
   * <p><b>GIF89a</b>: <i>Restore to background color.
   * The area used by the graphic must be restored to the background color.</i></p>
   */
  public static let DISPOSAL_BACKGROUND:Int32 = 2
  /**
   * GIF Disposal Method meaning clear canvas to frame before last.
   * <p><b>GIF89a</b>: <i>Restore to previous.
   * The decoder is required to restore the area overwritten by the graphic
   * with what was there prior to rendering the graphic.</i></p>
   */
  public static let DISPOSAL_PREVIOUS:Int32 = 3

  var ix:Int32=0
  var iy:Int32=0
  var iw:Int32=0
  var ih:Int32=0
  /**
   * Control Flag.
   */
  var interlace:Bool = false
  /**
   * Control Flag.
   */
  var transparency:Bool = false
  /**
   * Disposal Method.
   */
  var dispose:Int32=0
  /**
   * Transparency Index.
   */
  var transIndex:Int32 = 0
  /**
   * Delay, in milliseconds, to next frame.
   */
  var delay:Int32 = 0
  /**
   * Index in the raw buffer where we need to start reading to decode.
   */
  var bufferFrameStart:Int32=0
  /**
   * Local Color Table.
   */
  var lct:Array<UInt32> = Array<UInt32>()

  public func getDelay():Int32{
    return delay
  }
  public func getLct():Array<UInt32>{
    return lct
  }
}
