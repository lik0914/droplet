
package gifdecoder.glide.gif

class XBitmapTools {
	
	// The top 16 bits are ignored
	public static func writeUInt16(inInt: UInt16, outArray : Array<UInt8>, posi: Int64){
        outArray[posi+0] = UInt8(inInt & 0xFF)
        outArray[posi+1] = UInt8((inInt & 0xFF00) >> 8)
	}
	
	public static func writeInt16(inInt: Int16, outArray : Array<UInt8>, posi: Int64){
        outArray[posi+0] = UInt8(inInt & 0xFF)
        outArray[posi+1] = UInt8((UInt16(inInt) & 0xFF00) >> 8)
	}	
	public static func writeInt32(inInt:Int32, outArray : Array<UInt8>, posi: Int64){
        outArray[posi+0] = UInt8(UInt32(inInt) & 0x000000FF)
        outArray[posi+1] = UInt8((UInt32(inInt) & 0x0000FF00) >> 8)
        outArray[posi+2] = UInt8((UInt32(inInt) & 0x00FF0000) >> 16)
        outArray[posi+3] = UInt8((UInt32(inInt) & 0xFF000000) >> 24)
	}
	public static func writeUInt32(inInt:UInt32, outArray : Array<UInt8>, posi: Int64){
        outArray[posi+0] = UInt8(inInt & 0x000000FF)
        outArray[posi+1] = UInt8((inInt & 0x0000FF00) >> 8)
        outArray[posi+2] = UInt8((inInt & 0x00FF0000) >> 16)
        outArray[posi+3] = UInt8((inInt & 0xFF000000) >> 24)
	}
		
	
	public static func readUInt16(inArray : Array<UInt8>, posi: Int64) : UInt16
    {  // Returns unsigned int16
        //// AppLog.error("readUInt16 1:${inArray[posi+0]} 2:${inArray[posi+1]}")
		var val=UInt16(inArray[posi+0]) + (UInt16(inArray[posi+1])  << 8)
		//// AppLog.error("return : ${val}")
		return val
	}
	
	
	public static func readUInt32(inArray : Array<UInt8>, posi: Int64) : UInt32 {
		return UInt32(inArray[posi+0])  + (UInt32(inArray[posi+1]) <<8) +
            (UInt32(inArray[posi+2]) <<16) + (UInt32(inArray[posi+3]) << 24)
	}
	public static func readInt32(inArray : Array<UInt8>, posi: Int64) : Int32 {
		return Int32(inArray[posi+0])  + (Int32(inArray[posi+1]) <<8) +
            (Int32(inArray[posi+2]) <<16) + (Int32(inArray[posi+3]) << 24)
	}	
	//RGB To Gray
	public func bmpToGray(bmp :XBitmap) : Array<UInt8> {
		var width: Int64 = Int64(bmp.width)
		var height: Int64 = Int64(bmp.height)
		
		if(width <=0 || height <=0)
		{
			throw Exception("Error bitmap object")
		}
		var gray : Array<UInt8> = Array<UInt8> (width*height,item:0)
		for(y in 0..height)
		{
			for(x in 0..width)
			{
				var bmpGrayVal = 0.299 * Float64(bmp.image[y * width * 3 + x * 3])+ 	0.587 * Float64(bmp.image[y * width * 3 + x * 3 + 1])  + 0.114 * Float64(bmp.image[y * width * 3 + x * 3 + 2]); //计算灰度值
				gray[y*width +x] = UInt8(bmpGrayVal)
			}
		}
		return gray
	}
}
