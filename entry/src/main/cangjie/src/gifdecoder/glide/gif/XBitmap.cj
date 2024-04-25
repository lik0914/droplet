
package gifdecoder.glide.gif

public class XBitmap {
    public var width: Int32 = 0
    public var height: Int32 = 0 
    public var image:Array<UInt8> = Array<UInt8>()
	public var horizontalResolution : Int32 = 0
    public var verticalResolution : Int32 = 0
    private var topToBottom : Bool = true
    private var bitsPerPixel: UInt16 = 0

    public init()   
    {
        this.width = 0
        this.height = 0
        this.image = Array<UInt8>()
    }
    public init(fileName:String)
    {
        let bmp_in=File(fileName ,OpenOption.Open(true, false))
        if(bmp_in.canRead())
        {
            var data : Array<UInt8> = Array<UInt8>()
            data = bmp_in.readToEnd()
            readBmp(data)
            bmp_in.close()
        }
    }
	public init(width:Int32, height:Int32)
	{
        this.width = width
        this.height = height
        this.image = Array<UInt8>(Int64(this.width * this.height * 3), item:0)		
	}
    public func toString(): String 
    {
        "XBitmap width: ${width}, height: ${height}, bitsPerPixel:${bitsPerPixel}"
    } 
    private func readBmp(data : Array<UInt8>) 
    {
		// BITMAPFILEHEADER (14 bytes)
		var fileSize :UInt32
		var imageDataOffset : UInt32
        var bmpHeadMark :UInt16 = XBitmapTools.readUInt16(data, 0)
        
		if (bmpHeadMark != 0x4D42)   // "BM"
        {
            // AppLog.error("BMP signature = ${bmpHeadMark}")
			throw Exception("Invalid BMP signature : signature = ${bmpHeadMark}")
        }
		fileSize = XBitmapTools.readUInt32(data, 2)
		// Skip reserved 4 bytes
		imageDataOffset = XBitmapTools.readUInt32(data, 10)
     
		// BITMAPINFOHEADER
		var headerSize : UInt32 = XBitmapTools.readUInt32(data,14)

		var compression: UInt32
		var colorsUsed: UInt32

		if (headerSize == 40) {
			var planes :UInt16 
			var colorsImportant:UInt32
			this.width  = XBitmapTools.readInt32(data,18)
			this.height = XBitmapTools.readInt32(data,22)

			topToBottom = height < 0
			height = math.abs(height)

			planes = XBitmapTools.readUInt16(data,26);
			bitsPerPixel = XBitmapTools.readUInt16(data,28);
			compression = XBitmapTools.readUInt32(data,30);

			this.horizontalResolution = XBitmapTools.readInt32(data,34);
			this.verticalResolution   = XBitmapTools.readInt32(data,38);

			colorsUsed = XBitmapTools.readUInt32(data,42);
			colorsImportant = XBitmapTools.readUInt32(data,46);
			
			if (width <= 0)
            {
				throw Exception("Invalid width: ${width} ")
            }
			if (height == 0)
            {
				throw Exception("Invalid height:${ height} ")
            }
			if (planes != 1)
            {
				throw Exception("Unsupported planes:${planes} ");
            }
			if (bitsPerPixel == 1 || bitsPerPixel == 4 || bitsPerPixel == 8) {
				if (colorsUsed == 0)
                {
					colorsUsed = 1 << bitsPerPixel
                }
				if (colorsUsed > 1 << bitsPerPixel)
                {
					throw Exception("Invalid colors used: ${colorsUsed} ")
                }
				
			} else if (bitsPerPixel == 24 || bitsPerPixel == 32) {
				if (colorsUsed != 0)
				{
                    throw Exception("Invalid colors used: ${colorsUsed} ")
                }
				
			} else
            {
				throw Exception("Unsupported bits per pixel: ${bitsPerPixel}" )
            }
			if (compression == 0) {
			} else if (bitsPerPixel == 8 && compression == 1 || bitsPerPixel == 4 && compression == 2) {
				if (topToBottom)
                {
					throw Exception("Top-to-bottom order not supported for compression = 1 or 2");
                }
			} else {
				throw Exception("Unsupported compression: ${compression}" )
            }
			if (colorsImportant < 0 || colorsImportant > colorsUsed){
				throw Exception("Invalid important colors: ${colorsImportant}" )
            }
			
		} else {
			throw Exception("Unsupported BMP header format: ${headerSize} bytes");
        }
		// Some more checks
		if (14 + headerSize + 4 * colorsUsed > imageDataOffset){
			throw Exception("Invalid image data offset: ${imageDataOffset} ")
        }
		if (imageDataOffset > fileSize) {
			throw Exception("Invalid file size: ${fileSize}")
        }
    
		// Read the image data
		if (bitsPerPixel == 24 || bitsPerPixel == 32)
        {
			var posi:Int64=Int64(imageDataOffset - (14 + headerSize + 4 * colorsUsed)) + 54
			//// AppLog.error("posi=${posi} imageDataOffset=${imageDataOffset} headerSize=${headerSize} colorsUsed=${colorsUsed} ")
			readRgb24or32Image(data,posi)
        }
        else {
            var palette : Array<UInt32> = Array<UInt32>(Int64(colorsUsed), item:0)

			for ( i in 0..colorsUsed) {
				var entry:Array<UInt8> = Array<UInt8>(4, item:0)
				
				palette[Int64(i)] =XBitmapTools.readUInt32(data,50);
			}
			
			if (compression == 0)
			{
				var posi:Int64=Int64(imageDataOffset - (14 + headerSize + 4 * colorsUsed)) + 54
				readPalettedImage(palette, data, posi)
			} 
			else
			{
				throw Exception("RLE Compression BMP is not been supported.")
			}
		}
    }
  	private func readRgb24or32Image(data : Array<UInt8>, posi:Int64){
		var bytesPerPixel:UInt16 = bitsPerPixel / 8;
		
		var y:Int32
        var end:Int32
        var inc:Int32
		var raw_y:Int32 = 0

		if (topToBottom) {
			y = 0;
			end = height;
			inc = 1;
		} else {
			y = height - 1;
			end = -1;
			inc = -1;
		}
		this.image = Array<UInt8>(Int64(width * height * Int32(bytesPerPixel)), item:0)

		//// AppLog.error("posi=${posi}")
        while(y!=end){
			for (x in 0..width) {
				for(i in 0..Int64(bytesPerPixel)){
					this.image[Int64(y * width * Int32(bytesPerPixel) + x * Int32(bytesPerPixel)) + i] = data[Int64(y * width * Int32(bytesPerPixel) + x * Int32(bytesPerPixel)) + posi + i]
				}
			}
            y += inc
			raw_y += 1
		}
	}  

	private func readPalettedImage(palette : Array<UInt32>,data : Array<UInt8>,  posi:Int64){

		var pixelsPerByte = 8 / bitsPerPixel;
		var mask:UInt32 = (1 << bitsPerPixel) - 1;
		
		var y:Int32
        var end:Int32
        var inc:Int32
		var raw_y:Int32 = 0

		if (topToBottom) {
			y = 0;
			end = height;
			inc = 1;
		} else {
			y = height - 1;
			end = -1;
			inc = -1;
		}
		this.image = Array<UInt8>(Int64(width * height * 3), item:0)
        while(y!=end){
			for (x in 0..width) {
					var index = x / Int32(pixelsPerByte)
					var shift = (Int32(pixelsPerByte) - 1 - x % Int32(pixelsPerByte)) * Int32(bitsPerPixel)
					var pix:UInt8 = UInt8(UInt32(data[Int64(y * width  + index ) + posi ]) >> shift & mask)
					var color = palette[Int64(pix) & 0xFF];
					this.image[Int64(y * width + x )] = UInt8(color & 0x000000FF)
					this.image[Int64(y * width + x + 1)] = UInt8(color & 0x0000FF00 >> 8)
					this.image[Int64(y * width + x + 2)] = UInt8(color & 0x00FF0000 >> 16)
			}
            y += inc
			raw_y += 1
		}
	}	
	public func save(fileName:String) : Bool {
		var imageSize:Int32  = width * height * 3;

		let out1=File(fileName,OpenOption.CreateOrTruncate(false))
        if(out1.canWrite())
        {
			let head = Array<UInt8>(54,item:0)
			// BITMAPFILEHEADER
			head[0]=66
			head[1]=77
			XBitmapTools.writeInt32(Int32(14 + 40 + imageSize), head, 2) // FileSize
			XBitmapTools.writeInt32(0, head, 6)// Reserved1
			XBitmapTools.writeInt32(Int32(14 + 40), head, 10) // BitmapOffset

			// BITMAPINFOHEADER
			XBitmapTools.writeInt32(Int32(40), head, 14)                        // Size
			XBitmapTools.writeInt32(Int32(width), head, 18)                     // Width
			XBitmapTools.writeInt32(Int32(height), head, 22)                    // Height
			XBitmapTools.writeInt16(Int16(1), head, 26)                         // Planes
			XBitmapTools.writeInt16(Int16(24), head, 28)                        // BitsPerPixel
			XBitmapTools.writeInt32(Int32(0), head, 30)                         // Compression
			XBitmapTools.writeInt32(Int32(imageSize), head, 34)                 // SizeOfBitmap
			XBitmapTools.writeInt32(Int32(horizontalResolution), head, 38)  // HorzResolution
			XBitmapTools.writeInt32(Int32(verticalResolution), head, 42)    // VertResolution
			XBitmapTools.writeInt32(Int32(0), head, 46)                         // ColorsUsed
			XBitmapTools.writeInt32(Int32(0), head, 50)                         // ColorsImportant


			let a = ArrayList<UInt8>()
			a.appendAll(head)
			// out1.write(head)

			let row=Array<UInt8>(3,item:0)

			// Image data
			for (y in 0..height) {
				for (x in 0..width) {
					row[0] = this.image[Int64((height - 1 - y) * width *3 + x *3) + 0] 
					row[1] = this.image[Int64((height - 1 - y) * width *3 + x *3) + 1] 
					row[2] = this.image[Int64((height - 1 - y) * width *3 + x *3) + 2] 
					// out1.write(row);
					a.appendAll(row)
				}
				
			}

			out1.write(a.toArray());

			
			out1.flush();
            out1.close()
			
        }

		return true
	}
	public func set(y: Int32, x: Int32, ch: Int32, value: UInt8) {
		let idx = Int64(y * width * 3 + x * 3 + ch)
		image[idx] = value
	}	
	public func setData(data32:Array<UInt32>){
		for (y in 0..height) {
		let yw = y * width
		for (x in 0..width) {
			var p = data32[Int64(yw + x)]
			this.set(y, x, 0, UInt8((p & 0xff0000) >> 16))
			this.set(y, x, 1, UInt8((p & 0x00ff00) >> 8))
			this.set(y, x, 2, UInt8((p & 0x0000ff)))
		}
		}
	}
}
