package gifdecoder.glide.gif

/**
 * A class responsible for creating {@link com.bumptech.glide.gifdecoder.GifHeader}s from data
 * representing animated GIFs.
 *
 * @see <a href="https://www.w3.org/Graphics/GIF/spec-gif89a.txt">GIF 89a Specification</a>
 */
public class GifHeaderParser {
  private let logger: SimpleLogger = SimpleLogger()

  private static let TAG:String  = "GifHeaderParser";

  public static let MASK_INT_LOWEST_BYTE:Int32 = 0x000000FF;

  /** Identifies the beginning of an Image Descriptor. */
  public static let IMAGE_SEPARATOR:Int32 = 0x2C;
  /** Identifies the beginning of an extension block. */
  public static let EXTENSION_INTRODUCER:Int32 = 0x21;
  /** This block is a single-field block indicating the end of the GIF Data Stream. */
  public static let TRAILER:Int32 = 0x3B;
  // Possible labels that identify the current extension block.
  public static let LABEL_GRAPHIC_CONTROL_EXTENSION:Int32 = 0xF9;
  public static let LABEL_APPLICATION_EXTENSION:Int32 = 0xFF;
  public static let LABEL_COMMENT_EXTENSION:Int32 = 0xFE;
  public static let LABEL_PLAIN_TEXT_EXTENSION:Int32 = 0x01;

  // Graphic Control Extension packed field masks

  /**
   * Mask (bits 4-2) to extract Disposal Method of the current frame.
   *
   * @see GifFrame.GifDisposalMethod possible values
   */
  public static let GCE_MASK_DISPOSAL_METHOD:Int32 = 0b00011100;
  /**
   * Shift so the Disposal Method extracted from the packed value is on the least significant bit.
   */
  public static let GCE_DISPOSAL_METHOD_SHIFT:Int32 = 2;
  /**
   * Mask (bit 0) to extract Transparent Color Flag of the current frame.
   * <p><b>GIF89a</b>: <i>Indicates whether a transparency index is given
   * in the Transparent Index field.</i></p>
   * Possible values are:<ul>
   * <li>0 - Transparent Index is not given.</li>
   * <li>1 - Transparent Index is given.</li>
   * </ul>
   */
  public static let GCE_MASK_TRANSPARENT_COLOR_FLAG:Int32 = 0b00000001;

  // Image Descriptor packed field masks (describing Local Color Table)

  /**
   * Mask (bit 7) to extract Local Color Table Flag of the current image.
   * <p><b>GIF89a</b>: <i>Indicates the presence of a Local Color Table
   * immediately following this Image Descriptor.</i></p>
   */
  public static let DESCRIPTOR_MASK_LCT_FLAG:Int32 = 0b10000000;
  /**
   * Mask (bit 6) to extract Interlace Flag of the current image.
   * <p><b>GIF89a</b>: <i>Indicates if the image is interlaced.
   * An image is interlaced in a four-pass interlace pattern.</i></p>
   * Possible values are:<ul>
   * <li>0 - Image is not interlaced.</li>
   * <li>1 - Image is interlaced.</li>
   * </ul>
   */
  public static let DESCRIPTOR_MASK_INTERLACE_FLAG:Int32 = 0b01000000;
  /**
   * Mask (bits 2-0) to extract Size of the Local Color Table of the current image.
   * <p><b>GIF89a</b>: <i>If the Local Color Table Flag is set to 1, the value in this
   * field is used to calculate the number of bytes contained in the Local Color Table.
   * To determine that actual size of the color table, raise 2 to [the value of the field + 1].
   * This value should be 0 if there is no Local Color Table specified.</i></p>
   */
  public static let DESCRIPTOR_MASK_LCT_SIZE:Int32 = 0b00000111;

  // Logical Screen Descriptor packed field masks (describing Global Color Table)

  /**
   * Mask (bit 7) to extract Global Color Table Flag of the current image.
   * <p><b>GIF89a</b>: <i>Indicates the presence of a Global Color Table
   * immediately following this Image Descriptor.</i></p>
   * Possible values are:<ul>
   * <li>0 - No Global Color Table follows, the Background Color Index field is meaningless.</li>
   * <li>1 - A Global Color Table will immediately follow,
   * the Background Color Index field is meaningful.</li>
   * </ul>
   */
  public static let LSD_MASK_GCT_FLAG:Int32 = 0b10000000;
  /**
   * Mask (bits 2-0) to extract Size of the Global Color Table of the current image.
   * <p><b>GIF89a</b>: <i>If the Global Color Table Flag is set to 1, the value in this
   * field is used to calculate the number of bytes contained in the Global Color Table.
   * To determine that actual size of the color table, raise 2 to [the value of the field + 1].
   * Even if there is no Global Color Table specified, set this field according to the above
   * formula so that decoders can choose the best graphics mode to display the stream in.</i></p>
   */
  public static let LSD_MASK_GCT_SIZE:Int32 = 0b00000111;

  /** The minimum frame delay in hundredths of a second. */
  public static let MIN_FRAME_DELAY:Int32 = 2;
  /**
   * The default frame delay in hundredths of a second.
   * This is used for GIFs with frame delays less than the minimum.
   */
  public static let DEFAULT_FRAME_DELAY:Int32 = 10;

  public static let MAX_BLOCK_SIZE:Int64 = 256;
  // Raw data read working array.
  private var block:Array<UInt8> = Array<UInt8>(MAX_BLOCK_SIZE,item:0)

  private var rawData:ByteBuffer=ByteBuffer();
  private var header:GifHeader=GifHeader();
  private var blockSize:Int32 = 0;

  public func setData(data:ByteBuffer):GifHeaderParser {
    reset();
    rawData = data.asReadOnlyBuffer();
    rawData.setPosition(0);
    rawData.setOrder(ByteOrder.LITTLE_ENDIAN)
    return this;
  }

  public func setData(data:Array<UInt8>):GifHeaderParser {
    if (data.size > 0) {
      setData(ByteBuffer.wrap(data));
    } else {
      rawData = ByteBuffer();
      header.status = GifDecoder.STATUS_OPEN_ERROR;
    }
    return this;
  }

  public func clear() {
    rawData = ByteBuffer();
    header = GifHeader();
  }

  private func reset() {
    rawData = ByteBuffer();
    for(i in 0..block.size){
      block[i] = 0;
    }
    // block = Array<UInt8>(MAX_BLOCK_SIZE,item:0)
    //Arrays.fill(block, 0);
    header = GifHeader();
    blockSize = 0;
  }

  public func parseHeader():GifHeader{
    if (rawData.isEmpty()) {
      throw Exception("You must call setData() before parseHeader()");
    }
    if (err()) {
      return header;
    }
    //print("parseHeader step1\n")
    readHeader();
    if (!err()) {
      //print("parseHeader step2\n")
      readContents();
      if (header.frameCount < 0) {
        //print("parseHeader step3\n")
        header.status = GifDecoder.STATUS_FORMAT_ERROR;
      }
    }

    return header;
  }

  /**
   * Determines if the GIF is animated by trying to read in the first 2 frames
   * This method re-parses the data even if the header has already been read.
   */
  public func isAnimated():Bool {
    readHeader();
    if (!err()) {
      readContents(2 /* maxFrames */);
    }
    return header.frameCount > 1;
  }

  /**
   * Main file parser. Reads GIF content blocks.
   */
  private func readContents():Unit {
    readContents(Int32.Max /* maxFrames */);
  }

  /**
   * Main file parser. Reads GIF content blocks. Stops after reading maxFrames
   */
  private func readContents(maxFrames:Int32):Unit {
    // Read GIF file content blocks.
    var done:Bool = false
    while (!(done || err() || header.frameCount > maxFrames)) {
      
      var code:Int32 = read()
      //print("var code:Int32 = read()=${code}\n")
      if(code == IMAGE_SEPARATOR) {
          //print("IMAGE_SEPARATOR1\n")
          // The Graphic Control Extension is optional, but will always come first if it exists.
          // If one did exist, there will be a non-null current frame which we should use.
          // However if one did not exist, the current frame will be null
          // and we must create it here. See issue #134.
          readBitmap()
          //print("IMAGE_SEPARATOR2\n")
      }else if(code == EXTENSION_INTRODUCER){
          //print("EXTENSION_INTRODUCER1\n")
          var extensionLabel:Int32 = read()
          //print("EXTENSION_INTRODUCER2\n")
          if(extensionLabel == LABEL_GRAPHIC_CONTROL_EXTENSION) {
              //print("LABEL_GRAPHIC_CONTROL_EXTENSION1\n")
              // Start a new frame.
              header.currentFrame = GifFrame()
              readGraphicControlExt()
              //print("LABEL_GRAPHIC_CONTROL_EXTENSION2\n")
              //break;
          }else if(extensionLabel == LABEL_APPLICATION_EXTENSION){
            //print("LABEL_APPLICATION_EXTENSION1\n")
              readBlock()
              var app:Array<UInt8> = Array<UInt8>(11,item:0)
              for (i in 0..11) {
                app[i]=block[i]
              }
              //print("${app}\n")
              //print("${("NETSCAPE2.0").toUtf8Array()}\n")
              //适配
              //if (("NETSCAPE2.0").toUtf8Array() == app) {
              if (("NETSCAPE2.0").toArray() == app) {
                readNetscapeExt()
              } else {
                // Don't care.
                skip()
              }
              //print("LABEL_APPLICATION_EXTENSION2\n")
              //break;
          } else if(extensionLabel ==LABEL_COMMENT_EXTENSION ){
              //print("LABEL_COMMENT_EXTENSION1\n")
              skip()
              //print("LABEL_COMMENT_EXTENSION2\n")
          }else if(extensionLabel == LABEL_PLAIN_TEXT_EXTENSION){
              //print("LABEL_PLAIN_TEXT_EXTENSION1\n")
              skip()
              //print("LABEL_PLAIN_TEXT_EXTENSION2\n")
              //break;
          }else {
              // Uninteresting extension.
              //print("case _ B1\n")
              skip()
              //print("case _ B2\n")
          }
      } else if(code ==  TRAILER) {          // This block is a single-field block indicating the end of the GIF Data Stream.
        done = true
        //print("TRAILER\n")
      } else if(code == 0x00) {  
      // Bad byte, but keep going and see what happens
        header.status = GifDecoder.STATUS_FORMAT_ERROR
        //print("case 0x00 \n")
      } else {
        header.status = GifDecoder.STATUS_FORMAT_ERROR
        //print("case _ A \n")
      }
    }
  }

  /**
   * Reads Graphic Control Extension values.
   */
  private func readGraphicControlExt() {
    // Block size.
    read();
    /*
     * Graphic Control Extension packed field:
     *      7 6 5 4 3 2 1 0
     *     +---------------+
     *  1  |     |     | | |
     *
     * Reserved                    3 Bits
     * Disposal Method             3 Bits
     * User Input Flag             1 Bit
     * Transparent Color Flag      1 Bit
     */
    var packed:Int32 = read();
    // Disposal method.
    //noinspection WrongConstant field has to be extracted from packed value
    header.currentFrame.dispose = (packed & GCE_MASK_DISPOSAL_METHOD) >> GCE_DISPOSAL_METHOD_SHIFT;
    if (header.currentFrame.dispose == GifFrame.DISPOSAL_UNSPECIFIED) {
      // Elect to keep old image if discretionary.
      header.currentFrame.dispose = GifFrame.DISPOSAL_NONE;
    }
    header.currentFrame.transparency = (packed & GCE_MASK_TRANSPARENT_COLOR_FLAG) != 0;
    // Delay in milliseconds.
    var delayInHundredthsOfASecond:Int32 = readShort();
    // TODO: consider allowing -1 to indicate show forever.
    if (delayInHundredthsOfASecond < MIN_FRAME_DELAY) {
      delayInHundredthsOfASecond = DEFAULT_FRAME_DELAY;
    }
    header.currentFrame.delay = delayInHundredthsOfASecond * 10;
    // Transparent color index
    header.currentFrame.transIndex = read();
    // Block terminator
    read();
  }

  /**
   * Reads next frame image.
   */
  private func readBitmap() {
    // (sub)image position & size.
    header.currentFrame.ix = readShort();
    header.currentFrame.iy = readShort();
    header.currentFrame.iw = readShort();
    header.currentFrame.ih = readShort();
    //print("readBitmap 1 ix:${header.currentFrame.ix} iy:${header.currentFrame.iy} iw:${header.currentFrame.iw} ih:${header.currentFrame.ih}\n")
    /*
     * Image Descriptor packed field:
     *     7 6 5 4 3 2 1 0
     *    +---------------+
     * 9  | | | |   |     |
     *
     * Local Color Table Flag     1 Bit
     * Interlace Flag             1 Bit
     * Sort Flag                  1 Bit
     * Reserved                   2 Bits
     * Size of Local Color Table  3 Bits
     */
    var packed:Int32 = read();
    var lctFlag:Bool = (packed & DESCRIPTOR_MASK_LCT_FLAG) != 0;
    var lctSize:Int32 = Int32(pow(2.0, (packed & DESCRIPTOR_MASK_LCT_SIZE) + 1))
    //print("readBitmap 2 lctSize=${lctSize}\n")
    header.currentFrame.interlace = (packed & DESCRIPTOR_MASK_INTERLACE_FLAG) != 0;
    //print("rawData.getPosition()=${rawData.getPosition()}\n")
    if (lctFlag) {
      header.currentFrame.lct = readColorTable(lctSize);
    } else {
      // No local color table.
      header.currentFrame.lct = Array<UInt32>();
    }
    //print("readBitmap 3\n")
    // Save this as the decoding position pointer.
    header.currentFrame.bufferFrameStart = rawData.getPosition()
    //print("readBitmap 4 bufferFrameStart=${header.currentFrame.bufferFrameStart}\n")
    // False decode pixel data to advance buffer.
    skipImageData();
    //print("readBitmap 5\n")
    if (err()) {
      //print("readBitmap 6\n")
      return;
    }
    //print("readBitmap 7\n")
    header.frameCount++;
    // Add image to frame.
    header.frames.append(header.currentFrame);
    //print("readBitmap 8\n")
  }

  /**
   * Reads Netscape extension to obtain iteration count.
   */
  private func readNetscapeExt() {
    do {
      readBlock();
      if (block[0] == 1) {
        // Loop count sub-block.
        var b1:Int32 = (Int32(block[1])) & MASK_INT_LOWEST_BYTE;
        var b2:Int32 = (Int32(block[2])) & MASK_INT_LOWEST_BYTE;
        header.loopCount = (b2 << 8) | b1;
      }
    } while ((blockSize > 0) && !err());
  }


  /**
   * Reads GIF file header information.
   */
  private func readHeader() {
    var id:Array<UInt8> = Array<UInt8>(6,item:0)
    for (i in 0..6) {
      id[i] = UInt8(read())
    }
    var str:String =  String.fromUtf8(id)
   
    //print("readHead(0-6):${str}\n")
    if (!str.startsWith("GIF")) {
      header.status = GifDecoder.STATUS_FORMAT_ERROR;
      //print("readHeader() header.status = GifDecoder.STATUS_FORMAT_ERROR;\n")
      return;
    }
    readLSD();
    if (header.gctFlag && !err()) {
      header.gct = readColorTable(header.gctSize);
      header.bgColor = header.gct[Int64(header.bgIndex)];
    }
  }

  /**
   * Reads Logical Screen Descriptor.
   */
  private func readLSD() {
    // Logical screen size.
    header.width = readShort();
    header.height = readShort();
    /*
     * Logical Screen Descriptor packed field:
     *      7 6 5 4 3 2 1 0
     *     +---------------+
     *  4  | |     | |     |
     *
     * Global Color Table Flag     1 Bit
     * Color Resolution            3 Bits
     * Sort Flag                   1 Bit
     * Size of Global Color Table  3 Bits
     */
    var packed:Int32 = read();
    header.gctFlag = (packed & LSD_MASK_GCT_FLAG) != 0;
    header.gctSize = Int32(pow(2.0, (packed & LSD_MASK_GCT_SIZE) + 1))
    // Background color index.
    header.bgIndex = read();
    // Pixel aspect ratio
    header.pixelAspect = read();

    //print("width:${header.width} height:${header.height} gctFlag:${header.gctFlag} gctSize:${header.gctSize} bgIndex=${header.bgIndex} pixelAspect:${header.pixelAspect}\n")
  }

  /**
   * Reads color table as 256 RGB integer values.
   *
   * @param nColors int number of colors to read.
   * @return int array containing 256 colors (packed ARGB with full alpha).
   */
  private func readColorTable(nColors:Int32):Array<UInt32> {
    var nBytes:Int64 = 3 * Int64(nColors);
    var tab:Array<UInt32> = Array<UInt32>()
    var c:Array<UInt8> = Array<UInt8>(nBytes,item:0)

    try {
      rawData.getData(c);
      //print("readColorTable step1 nColors=${nColors} MAX_BLOCK_SIZE=${MAX_BLOCK_SIZE}\n")
      // TODO: what bounds checks are we avoiding if we know the number of colors?
      // Max size to avoid bounds checks.
      tab = Array<UInt32>(MAX_BLOCK_SIZE,item:0)
      var i:Int64 = 0;
      var j:Int64 = 0;
      while (i < Int64(nColors)) {
        var r:Int32 = (Int32(c[j])) & MASK_INT_LOWEST_BYTE;
        j++
        var g:Int32 = (Int32(c[j])) & MASK_INT_LOWEST_BYTE;
        j++
        var b:Int32 = (Int32(c[j])) & MASK_INT_LOWEST_BYTE;
        j++
        tab[i] = UInt32(0xFF000000) | UInt32((r << 16)) | UInt32((g << 8)) | UInt32(b);
        //print("${r}:${g}:${b} ")
        i++;
      }
      //print("\n")
    } catch (e :Exception) {
      //print("Format Error Reading Color Table: ${e}")
      logger.log(LogLevel.DEBUG,  "Format Error Reading Color Table ${e}");
      header.status = GifDecoder.STATUS_FORMAT_ERROR;
    }

    return tab;
  }

  /**
   * Skips LZW image data for a single frame to advance buffer.
   */
  private func skipImageData() {
    // lzwMinCodeSize
    read();
    // data sub-blocks
    skip();
  }

  /**
   * Skips variable length blocks up to and including next zero length block.
   */
  private func skip() :Unit{
    var blockSize:Int32 = 0
    do {
      blockSize = read();
      var newPosition:Int32 = min(rawData.getPosition() + blockSize, rawData.limit());
      //print("blockSize:${blockSize} newPosition:${newPosition}\n")
      rawData.setPosition(newPosition);
    } while (blockSize > 0);
  }

  /**
   * Reads next variable length block from input.
   */
  private func readBlock() {
    blockSize = read();
    var n:Int32 = 0;
    if (blockSize > 0) {
      var count:Int32 = 0;
      try {
        while (n < blockSize) {
          count = blockSize - n;
          rawData.getData(block, n, count);

          n += count;
        }
      } catch (e:Exception) {
        logger.log(LogLevel.DEBUG,  
              "Error Reading Block n: ${n} count: ${count} blockSize: ${blockSize} ${e}");
        header.status = GifDecoder.STATUS_FORMAT_ERROR;
      }
    }
  }

  /**
   * Reads a single byte from the input stream.
   */
  private func read():Int32 {
    var currByte:Int32 = 0;
    try {
      currByte = Int32(rawData.getByte()) & MASK_INT_LOWEST_BYTE;
    } catch (e: Exception) {
      print("Error  read():Int32 : ${e}\n")
      header.status = GifDecoder.STATUS_FORMAT_ERROR;
    }
    return currByte;
  }

  /**
   * Reads next 16-bit value, LSB first.
   */
  private func readShort():Int32 {
    // Read 16-bit value.
    return Int32(rawData.getShort())
  }

  private func err():Bool {
    //print("func err() header.status=${header.status}\n")
    return header.status != GifDecoder.STATUS_OK;
  }
}
