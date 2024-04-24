package glide.load.resource.gif

import gifdecoder.glide.gif.*

public class GifBitmapProvider <: BitmapProvider {
  public func obtain(width:Int32, height:Int32, config:Bitmap_Config):Bitmap {
    var result:Bitmap = Bitmap.createBitmap(width, height, config);
    //Shadows.shadowOf(result).setMutable(true);
    return result;
  }

  public func release(bitmap:Bitmap):Unit {
    // Do nothing.
  }

  public func obtainByteArray(size:Int32):Array<UInt8> {
    //print(">> obtainByteArray(size:Int32):Array<UInt8> size=${size}\n")
    return Array<UInt8>(Int64(size),item:0)
  }

  public func release(bytes1:Array<UInt8>):Unit{
    // Do nothing.
  }

  public func obtainIntArray(size:Int32):Array<UInt32> {
    return Array<UInt32>(Int64(size),item:0)
  }

  public func release(array:Array<UInt32>):Unit{
    // Do Nothing
  }
}
