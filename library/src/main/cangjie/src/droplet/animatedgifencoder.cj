/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2023-2024. All rights resvered.
 */

package droplet.droplet

/**
 * Class AnimatedGifEncoder - Encodes a GIF file consisting of one or more
 * frames.
 *
 * <pre>
 *  Example:
 *     AnimatedGifEncoder e = new AnimatedGifEncoder();
 *     e.start(outputFileName);
 *     e.setDelay(1000);   // 1 frame per sec
 *     e.addFrame(image1);
 *     e.addFrame(image2);
 *     e.addFrame(image3, 100, 100);    // set position of the frame
 *     e.finish();
 * </pre>
 *
 * No copyright asserted on the source code of this class. May be used for any
 * purpose, however, refer to the Unisys LZW patent for restrictions on use of
 * the associated LZWEncoder class. Please forward any corrections to
 *
 * @author Kevin Weiner, FM Software
 * @version 1.03 November 2003
 *
 */

public class AnimatedGifEncoder {
    private static let TAG:String = "AnimatedGifEncoder";

    // The minimum % of an images pixels that must be transparent for us to set a transparent index
    // automatically.
    private static let  MIN_TRANSPARENT_PERCENTAGE:Float64 = 4.0;

    private var width:Int32 = 0; // image size

    private var height:Int32 = 0;

    private var fixedWidth:Int32 = 0;   // set by setSize()

    private var fixedHeight:Int32 = 0;

    private var transparent:UInt32 = Color.TRANSPARENT  //= null; // transparent color if given

    private var transIndex:Int32 = 0; // transparent index in color table

    private var repeat:Int32 = -1; // no repeat

    private var delay:Int32 = 0; // frame delay (hundredths)

    private var started:Bool = false; // ready to output frames

    private var outFile:File;

    private var image:Bitmap = Bitmap(); // current frame

    private var pixels:Array<UInt8> = Array<UInt8>(); // BGR byte array from frame

    private var indexedPixels:Array<UInt8> =  Array<UInt8>(); // converted frame indexed to palette

    private var colorDepth:Int32 = 0; // number of bit planes

    private var colorTab:Array<UInt8> =  Array<UInt8>(); // RGB palette

    private var usedEntry:Array<Bool> = Array<Bool>(256,item:false); // active palette entries

    private var palSize:Int32 = 7; // color table size (bits-1)

    private var dispose:Int32 = -1; // disposal code (-1 = use default)

    private var closeStream:Bool = false; // close stream when finished

    private var firstFrame:Bool = true;

    private var sizeSet:Bool = false; // if false, get size from first frame

    private var sample:Int32 = 10; // default sample interval for quantizer

    private var hasTransparentPixels:Bool=false;

    /**
     * Initiates GIF file creation on the given stream. The stream is not closed
     * automatically.
     *
     * @param os
     *          OutputStream on which GIF images are written.
     * @return false if initial write failed.
     */
    public init(ifile:File ) {
        outFile = ifile
        if(outFile.canWrite()){
            started = true;
        }else{
            started = false
        }
   }

    /**
     * Initiates writing of a GIF file with the specified name.
     *
     * @param file
     *          String containing output file name.
     * @return false if open or initial write failed.
     */
    public init(file:String){
        outFile=File(file, OpenOption.CreateOrTruncate(false))
        try {
		    
            if(outFile.canWrite()){
                writeHeadMark()
                started = true;
            }else{
                outFile.close()
                started = false
            }
        } catch (e:IOException) {
            started = false
        }
    }
    public func isOpened():Bool{
        return started && outFile.canWrite()
    }
    public func writeHeadMark(){
        try {
            writeString("GIF89a"); // header
        } catch (e:IOException) {
            print("Error Exception:@{e}")
            started = false
        }
    }
    /**
     * Sets the delay time between each frame, or changes it for subsequent frames
     * (applies to last frame added).
     *
     * @param ms
     *          int delay time in milliseconds
     */
    public func setDelay( ms:Int32) {
        delay = Int32(round(Float64(ms) / 10.0))
    }


    public func setDispose(code:Int32) {
        if (code >= 0) {
            dispose = code;
        }
    }


    public func setRepeat(iter:Int32) {
        if (iter >= 0) {
            repeat = iter;
        }
    }


    public func setTransparent(color:UInt32) {
        transparent = color;
    }

    /**
     * Adds next GIF frame. The frame is not written immediately, but is actually
     * deferred until the next frame is received so that timing data can be
     * inserted. Invoking <code>finish()</code> flushes all frames. If
     * <code>setSize</code> was invoked, the size is used for all subsequent frames.
     * Otherwise, the actual size of the image is used for each frames.
     *
     * @param im
     *          BufferedImage containing frame to write.
     * @return true if successful.
     */
    public func addFrame(im:Bitmap):Bool {
        return addFrame(im, 0, 0);
    }

    /**
     * Adds next GIF frame to the specified position. The frame is not written immediately, but is
     * actually deferred until the next frame is received so that timing data can be inserted.
     * Invoking <code>finish()</code> flushes all frames. If <code>setSize</code> was invoked, the
     * size is used for all subsequent frames. Otherwise, the actual size of the image is used for
     * each frame.
     *
     *
     * @param im
     *          BufferedImage containing frame to write.
     * @param x
     *          Column number, in pixels, of the left edge of the image, with respect to the left
     *          edge of the Logical Screen.
     * @param y
     *          Row number, in pixels, of the top edge of the image with respect to the top edge of
     *          the Logical Screen.
     * @return true if successful.
     */
    public func addFrame(  im:Bitmap,  x:Int32,  y:Int32):Bool {
        if ((im.width==0) || !started) {
            return false;
        }
        var ok:Bool = true;
        try {
            if (sizeSet) {
                setFrameSize(fixedWidth, fixedHeight);
            } else {
                setFrameSize(im.getWidth(), im.getHeight());
            }
            image = Bitmap(im);

            getImagePixels(); // convert to correct format if necessary     
            
            analyzePixels(); // build color table & map pixels
            
            if (firstFrame) {
                writeLSD(); // logical screen descriptor
                writePalette(); // global color table
                if (repeat >= 0) {
                    // use NS app extension to indicate reps
                    writeNetscapeExt();
                }
            }
            writeGraphicCtrlExt(); // write graphic control extension
            writeImageDesc(x, y); // image descriptor
            if (!firstFrame) {
                writePalette(); // local color table
            }
            writePixels(); // encode and write pixel data
            firstFrame = false;
        } catch (e:IOException) {
            print("func addFrame() Exception:${e}")
            ok = false;
        }
        return ok;
    }

    /**
     * Flushes any pending data and closes output file. If writing to an
     * OutputStream, the stream is not closed.
     */
    public func finish():Bool {
        if (!started){
            return false;
        }
        var ok:Bool = true;
        started = false;
        try {
            outFile.write(0x3b); // GIF trailer
            outFile.flush();
            outFile.close();
        } catch (e:IOException) {
            print("func finish() Exception:${e}")
            ok = false;
        }

        // reset for subsequent use
        transIndex = 0;
        image = Bitmap();
        pixels =Array<UInt8>();
        indexedPixels = Array<UInt8>();
        colorTab = Array<UInt8>();
        closeStream = false;
        firstFrame = true;

        return ok;
    }

    /**
     * Sets frame rate in frames per second. Equivalent to
     * <code>setDelay(1000/fps)</code>.
     *
     * @param fps
     *          float frame rate (frames per second)
     */
    public func setFrameRate(fps:Float32) {
        if (abs(fps - 0.0)>0.001) {
            delay = Int32(round(Float32(100.0) / fps))
        }
    }


    public func setQuality(quality:Int32) {
        if (quality < 1){
            sample = 1;
        }else{
            sample = quality;
        }
    }

    /**
     * Sets the fixed GIF frame size for all the frames.
     * This should be called before start.
     *
     * @param w
     *          int frame width.
     * @param h
     *          int frame width.
     */
    public func setSize(w:Int32, h:Int32) {
        if (started) {
            return;
        }

        fixedWidth = w;
        fixedHeight = h;
        if (fixedWidth < 1) {
            fixedWidth = 320;
        }
        if (fixedHeight < 1) {
            fixedHeight = 240;
        }

        sizeSet = true;
    }

    /**
     * Sets current GIF frame size.
     *
     * @param w
     *          int frame width.
     * @param h
     *          int frame width.
     */
    private func setFrameSize(w:Int32, h:Int32) {
        width = w;
        height = h;
    }



    /**
     * Analyzes image colors and creates color map.
     */
    private func analyzePixels() {

        var len:Int32 = Int32(pixels.size)
        var nPix:Int32 = len / 3;
        indexedPixels = Array<UInt8>(Int64(nPix),item:0)
        var nq:NeuQuant = NeuQuant(pixels, len, sample);
        // initialize quantizer
        // 300ms
        colorTab = nq.process(); // create reduced palette
        // convert map from BGR to RGB
        var i:Int64=0

        while(i < colorTab.size){
            var temp:UInt8 = colorTab[i];
            colorTab[i] = colorTab[i + 2];
            colorTab[i + 2] = temp;
            usedEntry[i / 3] = false;
            i += 3
        }
       
        // map image pixels to new palette
        var k:Int64 = 0;
        // 70ms
        for ( i in 0..nPix) {
            var index:Int32 = nq.map(Int32(pixels[k] & 0xff), Int32(pixels[k+1] & 0xff), Int32(pixels[k+2] & 0xff));
            k +=3
            usedEntry[Int64(index)] = true;
            indexedPixels[Int64(i)] =UInt8(index)
        }

        pixels = Array<UInt8>()
        colorDepth = 8;
        palSize = 7;
        // get closest match to transparent color if specified
        if (transparent != Color.TRANSPARENT) {
            transIndex = findClosest(transparent);
        } else if (hasTransparentPixels) {
            transIndex = findClosest(Color.TRANSPARENT);
        }

    }

    /**
     * Returns index of palette color closest to c
     *
     */
    private func findClosest(color:UInt32):Int32 {
        if (colorTab.size==0){
            return -1;
        }
        var r:UInt32 = Color.red(color);
        var g:UInt32 = Color.green(color);
        var b:UInt32 = Color.blue(color);
        var minpos:Int32 = 0;
        var dmin:Int32 = 256 * 256 * 256;
        var len:Int32 = Int32(colorTab.size)
        var i:Int64=0
        while(i < Int64(len)) {
            var dr:Int32 = Int32(r) - Int32(colorTab[i] & 0xff)
            i++
            var dg:Int32 = Int32(g) - Int32(colorTab[i] & 0xff)
            i++
            var db:Int32 = Int32(b) - Int32(colorTab[i] & 0xff)
            var d:Int32 = dr * dr + dg * dg + db * db;
            var index:Int64 = i / 3;
            if (usedEntry[index] && (d < dmin)) {
                dmin = d;
                minpos = Int32(index);
            }
            i++;
        }
        return minpos;
    }

    /**
     * Extracts image pixels into byte array "pixels"
     */
    private func getImagePixels() {
        var w:Int32 = image.getWidth();
        var h:Int32 = image.getHeight();
        if ((w != width) || (h != height)) {
            // create new image with right size/format
            var temp:Bitmap = Bitmap.createBitmap(width, height, Bitmap_Config.ARGB_8888);
            image = Bitmap.createBitmap(width, height, Bitmap_Config.ARGB_8888);
            w = image.getWidth();
            h = image.getHeight();
        }
        var pixelsInt:Array<UInt32> = Array<UInt32>(Int64(w * h) ,item:0)
        image.getPixels(pixelsInt, 0, w, w, h);
        pixels = Array<UInt8>(Int64(pixelsInt.size * 3), item:0)
        var pixelsIndex:Int64 = 0;
        hasTransparentPixels = false;
        var totalTransparentPixels:Int32 = 0;
        for (pixel in pixelsInt) {
            if (pixel == Color.TRANSPARENT) {
                totalTransparentPixels++;
            }
            pixels[pixelsIndex] = UInt8(pixel & 0xFF);
            pixelsIndex++
            pixels[pixelsIndex] = UInt8((pixel >> 8) & 0xFF);
            pixelsIndex++
            pixels[pixelsIndex] = UInt8((pixel >> 16) & 0xFF);
            pixelsIndex++
        }

        var transparentPercentage:Float64 = 100.0 * Float64(totalTransparentPixels) / Float64(pixelsInt.size)
        // Assume images with greater where more than n% of the pixels are transparent actually have
        // transparency. See issue #214.
        hasTransparentPixels = transparentPercentage > MIN_TRANSPARENT_PERCENTAGE;
    }

    /**
     * Writes Graphic Control Extension
     */
    private func writeGraphicCtrlExt() {
        outFile.write(0x21); // extension introducer
        outFile.write(0xf9); // GCE label
        outFile.write(4); // data block size
        var transpcj:Int32
        var dispcj:Int32
        if (transparent == Color.TRANSPARENT && !hasTransparentPixels) {
            transpcj = 0;
            dispcj = 0; // dispose = no action
        } else {
            transpcj = 1;
            dispcj = 2; // force clear if using transparent color
        }
        if (dispose >= 0) {
            dispcj = dispose & 7; // user override
        }
        dispcj <<= 2;

        // packed fields
        outFile.write(UInt8(0 | // 1:3 reserved
                dispcj | // 4:6 disposal
                0 | // 7 user input - 0 = none
                transpcj)); // 8 transparency flag

        writeShort(delay); // delay x 1/100 sec
        outFile.write(UInt8(transIndex)); // transparent color index
        outFile.write(0); // block terminator
    }

    /**
     * Writes Image Descriptor
     */
    private func writeImageDesc(x:Int32, y:Int32) {
        outFile.write(0x2c); // image separator
        writeShort(x); // image position
        writeShort(y);
        writeShort(width); // image size
        writeShort(height);
        // packed fields
        if (firstFrame) {
            // no LCT - GCT is used for first (or only) frame
            outFile.write(0);
        } else {
            // specify normal LCT
            // 1 local color table 1=yes 2 interlace - 0=no  3 sorted - 0=no 4-5 reserved
            outFile.write(UInt8(0x80) | UInt8(0) |UInt8(0) | UInt8(0) | UInt8(palSize)); // 6-8 size of color table
        }
    }

    /**
     * Writes Logical Screen Descriptor
     */
    private func writeLSD() {
        // logical screen size
        writeShort(width);
        writeShort(height);
        // packed fields
        let t: UInt8 = UInt8(0x80 | // 1 : global color table flag = 1 (gct used)
                0x70 | // 2-4 : color resolution = 7
                0x00 | // 5 : gct sort flag = 0
                palSize);
        outFile.write(Array<UInt8>(1, item: t)); // 6-8 : gct size

        outFile.write(Array<UInt8>(1,item:0)); // background color index
        outFile.write(Array<UInt8>(1,item:0)); // pixel aspect ratio - assume 1:1
    }

    /**
     * Writes Netscape application extension to define repeat count.
     */
    private func writeNetscapeExt() {
        outFile.write(Array<UInt8>(1, item: 0x21)); // extension introducer
        outFile.write(0xff); // app extension label
        outFile.write(11); // block size
        writeString("NETSCAPE" + "2.0"); // app id + auth code
        outFile.write(3); // sub-block size
        outFile.write(1); // loop sub-block id
        writeShort(repeat); // loop count (extra iterations, 0=repeat forever)
        outFile.write(0); // block terminator
    }

    /**
     * Writes color table
     */
    private func writePalette() {
        outFile.write(colorTab);
        var n:Int32 = (3 * 256) - Int32(colorTab.size)
        for (i  in 0..n) {
            outFile.write(Array<UInt8>(1, item: 0));
        }
    }

    /**
     * Encodes and writes pixel data
     */
    private func writePixels() {
        var encoder:LZWEncoder = LZWEncoder(width, height, indexedPixels, colorDepth);
        encoder.encode(outFile);
    }

    /**
     * Write 16-bit value to output stream, LSB first
     */
    private func writeShort(value:Int32){
        var temp:Array<UInt8> = [UInt8(value & 0xff),UInt8((value >> 8) & 0xff)]
        outFile.write(temp);
    }

    /**
     * Writes string to output stream
     */
    private func writeString(s:String) {
        var bytes1=s.toArray()
        for (i in 0..s.size) {
            outFile.write(Array<UInt8>(1, item: bytes1[i]));
        }
    }
}
