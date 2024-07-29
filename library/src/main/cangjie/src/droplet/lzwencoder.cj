/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2023-2024. All rights resvered.
 */

package droplet.droplet

// ==============================================================================
// Adapted from Jef Poskanzer's Java port by way of J. M. G. Elliott.
// K Weiner 12/00
class LZWEncoder {

    private static let EOF:Int32 = -1;

    private var imgW:Int32
    private var imgH:Int32

    private var pixAry:Array<UInt8>;

    private var initCodeSize:Int32 = 0

    private var remaining:Int32 = 0

    private var curPixel:Int32 = 0

    // GIFCOMPR.C - GIF Image compression routines
    //
    // Lempel-Ziv compression based on 'compress'. GIF modifications by

    // General DEFINEs

    static let BITS:Int32 = 12;

    static let HSIZE:Int32 = 5003; // 80% occupancy



    var n_bits:Int32 = 0 // number of bits/code

    var maxbits:Int32 = BITS; // user settable max # bits/code

    var maxcode:Int32 = 0; // maximum code, given n_bits

    var maxmaxcode:Int32 = 1 << BITS; // should NEVER generate this code

    var htab:Array<Int32> = Array<Int32>(Int64(HSIZE), item:0)

    var codetab:Array<Int32> = Array<Int32>(Int64(HSIZE),item:0)

    var hsize:Int32 = HSIZE; // for dynamic table sizing

    var free_ent:Int32 = 0; // first unused entry

    // block compression parameters -- after all codes are used up,
    // and compression rate changes, start over.
    var clear_flg:Bool = false;



    var g_init_bitscj:Int32 = 0

    var ClearCode:Int32 = 0

    var EOFCode:Int32 = 0



    var cur_accum:Int32 = 0;

    var cur_bits:Int32 = 0;

    var  masks:Array<Int32>= [0x0000, 0x0001, 0x0003, 0x0007, 0x000F, 0x001F, 0x003F, 0x007F, 0x00FF, 0x01FF,
            0x03FF, 0x07FF, 0x0FFF, 0x1FFF, 0x3FFF, 0x7FFF, 0xFFFF]

    // Number of characters so far in this 'packet'
    var a_count:Int32 = 0

    // Define the storage for the packet accumulator
    var accum:Array<UInt8> = Array<UInt8>(256,item:0)

    // ----------------------------------------------------------------------------
    public init( width:Int32, height:Int32, pixels:Array<UInt8>, color_depth:Int32) {
        imgW = width;
        imgH = height;
    //    print(">>>>>>>>>>>>>>>>LZWEncoder.init() pixels.size=${pixels.size}\n")
        pixAry = pixels;
    //    print(">>>>>>>>>>>>>>>>LZWEncoder.init() pixAry.size=${pixAry.size}\n")
    //    print(pixels)
        initCodeSize = max(2, color_depth);
    }

    // Add a character to the end of the current packet, and if it is 254
    // characters, flush the packet to disk.
    public func char_out(c:UInt8, outs:File) {
        accum[Int64(a_count)] = c;
        a_count++
        if (a_count >= 254){
            flush_char(outs);
        }
    }

    // Clear out the hash table

    // table clear for block compress
    public func cl_block(outs:File) {
        cl_hash(hsize);
        free_ent = ClearCode + 2;
        clear_flg = true;

        output(ClearCode, outs);
    }

    // reset code table
    public func cl_hash( hsize:Int32) {
        for (i in 0..hsize){
            htab[Int64(i)] = -1;
        }
    }

    public func compress( init_bits:Int32,  outs:File){
        var fcode:Int32;
        var i:Int32 = 0 /* = 0 */;
        var c:Int32;
        var ent:Int32
        var disp:Int32
        var hsize_reg:Int32
        var hshift:Int32

        // Set up the globals: g_init_bits - initial number of bits
        g_init_bitscj = init_bits;

        // Set up the necessary values
        clear_flg = false;
        n_bits = g_init_bitscj;
        maxcode = MAXCODE(n_bits);
        //print("func compress() step1\n")
        ClearCode = 1 << (init_bits - 1);
        EOFCode = ClearCode + 1;
        free_ent = ClearCode + 2;

        a_count = 0; // clear packet
        //print("func compress() step2\n")
        ent = nextPixel();
        //print("func compress() step3\n")
        hshift = 0;
        fcode = hsize;
        while(fcode < 65536){
            fcode *= 2
            hshift++;
        }
        //print("func compress() step4\n")
        hshift = 8 - hshift; // set hash code range bound

        hsize_reg = hsize;
        //print("func compress() step5\n")
        cl_hash(hsize_reg); // clear hash table
        //print("func compress() step6\n")

        //print("#")
        output(ClearCode, outs);
        //print("func compress() step7\n")
        var outer_loop:Bool = false
        while (outer_loop == false) {
            c = nextPixel()
            //print("${c} ")
            if(c == EOF){
                break;
            }
            fcode = (c << maxbits) + ent;
            i = (c << hshift) ^ ent; // xor hashing

            if (htab[Int64(i)] == fcode) {
                ent = codetab[Int64(i)];
                continue;
            } else if (htab[Int64(i)] >= 0) // non-empty slot
            {
                disp = hsize_reg - i; // secondary hash (after G. Knott)
                if (i == 0){
                    disp = 1;
                }
                do {
                    i -= disp
                    if (i < 0){
                        i += hsize_reg;
                    }

                    if (htab[Int64(i)] == fcode) {
                        ent = codetab[Int64(i)];
                        outer_loop = true
                        break;
                    }
                } while (htab[Int64(i)] >= 0);
                if(outer_loop){
                    outer_loop=false
                    continue;
                }
            }
            //print("@")
            output(ent, outs);
            ent = c;
            if (free_ent < maxmaxcode) {
                codetab[Int64(i)] = free_ent; // code -> hashtable
                free_ent++
                htab[Int64(i)] = fcode;
            } else{
                cl_block(outs);
            }
        }
        //print("func compress() step8\n")
        // Put out the final code.
        print("!!!!")
        output(ent, outs);
        //print("func compress() step9\n")
        output(EOFCode, outs);
        //print("func compress() end\n")
    }
    // ----------------------------------------------------------------------------
    public func encode(os:File) {
        //var out1:Array<UInt8> =Array<UInt8>(4,item:0)
        //print("func encode() step1 initCodeSize=${initCodeSize}\n")
        //XBitmapTools.writeInt32(initCodeSize, out1, 0) 
        //print("func encode() step2\n")
        //os.write(out1); // write "initial code size" byte
        os.write(Array<UInt8>(1, item: UInt8(initCodeSize)))
        //print("func encode() step3\n")
        remaining = imgW * imgH; // reset navigation variables
        curPixel = 0;
        //print("func encode() step4\n")
        compress(initCodeSize + 1, os); // compress and write the pixel data
        //print("func encode() step5\n")
        os.write(Array<UInt8>(1, item: 0)); // write block terminator
        //print("func encode() step6\n")
    }

    // Flush the packet to disk, and reset the accumulator
    public func flush_char(outs:File) {
        if (a_count > 0) {
            //print(".")
            //var out1:Array<UInt8> =Array<UInt8>(4,item:0)
            //XBitmapTools.writeInt32(a_count, out1, 0) 
            //outs.write(out1);
            outs.write(Array<UInt8>(1, item:UInt8(a_count)))
            outs.write(accum.slice(0, Int64(a_count)));
            a_count = 0;
        }
    }

    public func MAXCODE(n_bits:Int32):Int32 {
        return (1 << n_bits) - 1;
    }

    // ----------------------------------------------------------------------------
    // Return the next pixel from the image
    // ----------------------------------------------------------------------------
    private func nextPixel():Int32 {
       // print("func nextPixel() step1\n")
        if (remaining == 0){
            return EOF;
        }

        remaining--;
       // print("func nextPixel() step2 curPixel=${curPixel} pixAry.size=${pixAry.size}\n")
        var pix:UInt8 = pixAry[Int64(curPixel)];
        //print("func nextPixel() step3\n")
        curPixel++

        return Int32(pix & UInt8(0xff));
    }

    public func output(codecj:Int32, outscj:File) {
        //print("*")
        cur_accum &= masks[Int64(cur_bits)];

        if (cur_bits > 0){
            cur_accum |= (codecj << cur_bits);
        }
        else{
            cur_accum = codecj;
        }

        cur_bits += n_bits;

        while (cur_bits >= 8) {
            char_out(UInt8(cur_accum & 0xff), outscj);
            cur_accum >>= 8;
            cur_bits -= 8;
        }

        // If the next entry is going to be too big for the code size,
        // then increase it, if possible.
        if (free_ent > maxcode || clear_flg) {
            if (clear_flg) {
                n_bits = g_init_bitscj;
                maxcode = MAXCODE(n_bits);
                clear_flg = false;
            } else {
                n_bits++;
                if (n_bits == maxbits){
                    maxcode = maxmaxcode;
                }
                else{
                    maxcode = MAXCODE(n_bits);
                }
            }
        }

        if (codecj == EOFCode) {
            // At EOF, write the rest of the buffer.
            while (cur_bits > 0) {
                char_out(UInt8 (cur_accum & 0xff), outscj);
                cur_accum >>= 8;
                cur_bits -= 8;
            }

            flush_char(outscj);
        }
    }
}
