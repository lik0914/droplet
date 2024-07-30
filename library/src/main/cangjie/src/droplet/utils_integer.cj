/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2023-2024. All rights resvered.
 */
 
package droplet.droplet

extend Rune {
  public func digit(radix: Int64): Int64 {
    let MIN_RADIX: Int64 = 2;
    let MAX_RADIX: Int64 = 36;
    var value: Int64 = -1;
    if(radix >= MIN_RADIX && radix <= MAX_RADIX) {
      value = match(this) {
        case r'0' => 0
        case r'1' => 1
        case r'2' => 2
        case r'3' => 3
        case r'4' => 4
        case r'5' => 5
        case r'6' => 6
        case r'7' => 7
        case r'8' => 8
        case r'9' => 9
        case r'a' | r'A' => 10
        case r'b' | r'B' => 11
        case r'c' | r'C' => 12
        case r'd' | r'D' => 13
        case r'e' | r'E' => 14
        case r'f' | r'F' => 15
        case _ => -1
      }
    }
    
    return value
  }

}

public class Integer {

    /**
     * The number of bits used to represent an {@code int} value in twos
     * complement binary form.
     *
     * @since 1.5
     */
    public static let SIZE: Int64 = 32;

    public static let MAX_VALUE_64: Int64 = 0x7fffffffffffffff;
    public static let MIN_VALUE_64: Int64 = -0x7fffffffffffffff;

    public static let MAX_VALUE: Int32 = 0x7fffffff;
    public static let MIN_VALUE: Int32 = -0x7fffffff;

    public static let DigitTens:Array<Rune> = [
        r'0' , r'0', r'0', r'0', r'0', r'0', r'0', r'0', r'0', r'0',
        r'1' , r'1', r'1', r'1', r'1', r'1', r'1', r'1', r'1', r'1',
        r'2' , r'2', r'2', r'2', r'2', r'2', r'2', r'2', r'2', r'2',
        r'3' , r'3', r'3', r'3', r'3', r'3', r'3', r'3', r'3', r'3',
        r'4' , r'4', r'4', r'4', r'4', r'4', r'4', r'4', r'4', r'4',
        r'5' , r'5', r'5', r'5', r'5', r'5', r'5', r'5', r'5', r'5',
        r'6' , r'6', r'6', r'6', r'6', r'6', r'6', r'6', r'6', r'6',
        r'7' , r'7', r'7', r'7', r'7', r'7', r'7', r'7', r'7', r'7',
        r'8' , r'8', r'8', r'8', r'8', r'8', r'8', r'8', r'8', r'8',
        r'9', r'9', r'9', r'9', r'9', r'9', r'9', r'9', r'9', r'9'
     ];

    public static let DigitOnes:Array<Rune> = [
        r'0' , r'1', r'2', r'3', r'4', r'5', r'6', r'7', r'8', r'9',
        r'0' , r'1', r'2', r'3', r'4', r'5', r'6', r'7', r'8', r'9',
        r'0' , r'1', r'2', r'3', r'4', r'5', r'6', r'7', r'8', r'9',
        r'0' , r'1', r'2', r'3', r'4', r'5', r'6', r'7', r'8', r'9',
        r'0' , r'1', r'2', r'3', r'4', r'5', r'6', r'7', r'8', r'9',
        r'0' , r'1', r'2', r'3', r'4', r'5', r'6', r'7', r'8', r'9',
        r'0' , r'1', r'2', r'3', r'4', r'5', r'6', r'7', r'8', r'9',
        r'0' , r'1', r'2', r'3', r'4', r'5', r'6', r'7', r'8', r'9',
        r'0' , r'1', r'2', r'3', r'4', r'5', r'6', r'7', r'8', r'9',
        r'0', r'1', r'2', r'3', r'4', r'5', r'6', r'7', r'8', r'9'
    ];

    /**
     * All possible chars for representing a number as a String
     */
    public static let digits:Array<Rune> = [
        r'0', r'1' , r'2' , r'3' , r'4' , r'5' ,
        r'6', r'7' , r'8' , r'9' , r'a' , r'b' ,
        r'c', r'd' , r'e' , r'f' , r'g' , r'h' ,
        r'i', r'j' , r'k' , r'l' , r'm' , r'n' ,
        r'o', r'p' , r'q' , r'r' , r's' , r't' ,
        r'u', r'v' , r'w' , r'x' , r'y' , r'z'
    ];


    public static func numberOfLeadingZeros(value: Int32): Int64 {
        var i = value
        // HD, Figure 5-6
        if (i == 0) {
            return 32;
        }

        var n: Int64 = 1;
        if (UInt32(0xffffffffi64 & Int64(i)) >> 16 == 0) { n += 16; i <<= 16; }
        if (UInt32(0xffffffffi64 & Int64(i)) >> 24 == 0) { n +=  8; i <<=  8; }
        if (UInt32(0xffffffffi64 & Int64(i)) >> 28 == 0) { n +=  4; i <<=  4; }
        if (UInt32(0xffffffffi64 & Int64(i)) >> 30 == 0) { n +=  2; i <<=  2; }
        n -= Int64(UInt32(0xffffffffi64 & Int64(i)) >> 31);
        return n;
    }

    public static func int64ToInt32(v: Int64): Int32 {
        var value = v;
        if((value & 0xffffffff) == 0x80000000) {
            // +-2,147,483,648
            return 1<<31;
        }
        if((value & 0x80000000) == 0) {
            value = (value & 0x7fffffff)
        } else {
            value = -(((!value) + 1) & 0x7fffffff)
        }

        return Int32(value);
    }

    public static func unsignedShiftRight(c: Int32, num: Int64) {
        Int32(UInt32(0xffffffffi64 & Int64(c)) >> num)
    }

    public static func unsignedShiftRight64(c: Int64, num: Int64) {
        let t: Int64 = 0x7fffffffffffffff<<1 | 0x01;
        Int64(UInt64(t & c) >> num)
    }


    public static func numberOfTrailingZeros(value: Int32): Int64 {
        var i = value;
        // HD, Figure 5-14
        var y: Int32;
        if (i == 0) {
            return 32;
        }
        var n: Int64 = 31;
        y = i <<16; if (y != 0) { n = n -16; i = y; }
        y = i << 8; if (y != 0) { n = n - 8; i = y; }
        y = i << 4; if (y != 0) { n = n - 4; i = y; }
        y = i << 2; if (y != 0) { n = n - 2; i = y; }
        return n - Int64(UInt32(0xffffffffi64 & Int64(i << 1)) >> 31);//n - ((i << 1) >>> 31);
    }


    public static func bitCount(v: Int32): Int32 {
        var i = v;
        i = i - (Int32(UInt32(0xffffffffi64 & Int64(i)) >> 1) & 0x55555555);
        i = (i & 0x33333333) + (Int32(UInt32(0xffffffffi64 & Int64(i)) >> 2) & 0x33333333);
        i = (i + Int32(UInt32(0xffffffffi64 & Int64(i)) >> 4)) & 0x0f0f0f0f;
        i = i + Int32(UInt32(0xffffffffi64 & Int64(i)) >> 8);
        i = i + Int32(UInt32(0xffffffffi64 & Int64(i)) >> 16);
        return i & 0x3f;
    }

    public static func parseInt64(s: String, radix: Int64): Int64 {
        /*
        * WARNING: This method may be invoked early during VM initialization
        * before IntegerCache is initialized. Care must be taken to not use
        * the valueOf method.
        */
        let MIN_RADIX: Int64 = 2;
        let MAX_RADIX: Int64 = 36;

        if (radix < MIN_RADIX) {
            throw Exception();
        }

        if (radix > MAX_RADIX) {
            throw Exception();
        }

        var result: Int64 = 0;
        var negative: Bool = false;
        var i: Int64 = 0;
        var len: Int64 = s.size;
        var limit: Int64 = -Integer.MAX_VALUE_64;
        var multmin = 0;
        var digit = 0;

        if (len > 0) {
            var firstChar: Rune = s.toRuneArray()[0]
            if (firstChar < r'0') { // Possible leading "+" or "-"
                if (firstChar == r'-') {
                    negative = true;
                    limit = Integer.MIN_VALUE_64;
                } else if (firstChar != r'+') {
                throw Exception();
                }

                if (len == 1) {
                // Cannot have lone "+" or "-"
                throw Exception();
                }
                i++;
            }
            multmin = limit / radix;
            while (i < len) {
                // Accumulating negatively avoids surprises near MAX_VALUE
                digit = s.toRuneArray()[i].digit(radix)
                i++;
                if (digit < 0) {
                    throw Exception();
                }
                if (result < multmin) {
                    throw Exception();
                }
                result *= radix;
                if (result < limit + digit) {
                    throw Exception();
                }
                result -= digit;
            }
        } else {
            throw Exception();
        }
        return if(negative) {result} else {-result};
    }

    public static func highestOneBit(i: Int64): Int64 {
        var i2 = i
        i2 |= (i2 >>  1);
        i2 |= i2 | (i2 >>  2);
        i2 |= (i2 >>  4);
        i2 |= (i2 >>  8);
        i2 |= (i2 >> 16);
        return i2 - unsignedShiftRight64(i2, 1);  
    }
}