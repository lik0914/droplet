package glide.util.utils

extend Char {
  public func digit(radix: Int64): Int64 {
    let MIN_RADIX: Int64 = 2;
    let MAX_RADIX: Int64 = 36;
    var value: Int64 = -1;
    if(radix >= MIN_RADIX && radix <= MAX_RADIX) {
      value = match(this) {
        case '0' => 0
        case '1' => 1
        case '2' => 2
        case '3' => 3
        case '4' => 4
        case '5' => 5
        case '6' => 6
        case '7' => 7
        case '8' => 8
        case '9' => 9
        case 'a' | 'A' => 10
        case 'b' | 'B' => 11
        case 'c' | 'C' => 12
        case 'd' | 'D' => 13
        case 'e' | 'E' => 14
        case 'f' | 'F' => 15
        case _ => -1
      }
    }
    
    return value
  }

}

public class Integer {

    /**
     * The number of bits used to represent an {@code int} value in two's
     * complement binary form.
     *
     * @since 1.5
     */
    public static let SIZE: Int64 = 32;

    public static let MAX_VALUE_64: Int64 = 0x7fffffffffffffff;
    public static let MIN_VALUE_64: Int64 = -0x7fffffffffffffff;

    public static let MAX_VALUE: Int32 = 0x7fffffff;
    public static let MIN_VALUE: Int32 = -0x7fffffff;

    public static let DigitTens:Array<Char> = [
        '0' , '0', '0', '0', '0', '0', '0', '0', '0', '0',
        '1' , '1', '1', '1', '1', '1', '1', '1', '1', '1',
        '2' , '2', '2', '2', '2', '2', '2', '2', '2', '2',
        '3' , '3', '3', '3', '3', '3', '3', '3', '3', '3',
        '4' , '4', '4', '4', '4', '4', '4', '4', '4', '4',
        '5' , '5', '5', '5', '5', '5', '5', '5', '5', '5',
        '6' , '6', '6', '6', '6', '6', '6', '6', '6', '6',
        '7' , '7', '7', '7', '7', '7', '7', '7', '7', '7',
        '8' , '8', '8', '8', '8', '8', '8', '8', '8', '8',
        '9', '9', '9', '9', '9', '9', '9', '9', '9', '9'
     ];

    public static let DigitOnes:Array<Char> = [
        '0' , '1', '2', '3', '4', '5', '6', '7', '8', '9',
        '0' , '1', '2', '3', '4', '5', '6', '7', '8', '9',
        '0' , '1', '2', '3', '4', '5', '6', '7', '8', '9',
        '0' , '1', '2', '3', '4', '5', '6', '7', '8', '9',
        '0' , '1', '2', '3', '4', '5', '6', '7', '8', '9',
        '0' , '1', '2', '3', '4', '5', '6', '7', '8', '9',
        '0' , '1', '2', '3', '4', '5', '6', '7', '8', '9',
        '0' , '1', '2', '3', '4', '5', '6', '7', '8', '9',
        '0' , '1', '2', '3', '4', '5', '6', '7', '8', '9',
        '0', '1', '2', '3', '4', '5', '6', '7', '8', '9'
    ];

    /**
     * All possible chars for representing a number as a String
     */
    public static let digits:Array<Char> = [
        '0', '1' , '2' , '3' , '4' , '5' ,
        '6', '7' , '8' , '9' , 'a' , 'b' ,
        'c', 'd' , 'e' , 'f' , 'g' , 'h' ,
        'i', 'j' , 'k' , 'l' , 'm' , 'n' ,
        'o', 'p' , 'q' , 'r' , 's' , 't' ,
        'u', 'v' , 'w' , 'x' , 'y' , 'z'
    ];


    public static func numberOfLeadingZeros(value: Int32): Int64 {
        var i = value
        // HD, Figure 5-6
        if (i == 0) {
            return 32;
        }

        var n: Int64 = 1;
        // if (i >>> 16 == 0) { n += 16; i <<= 16; }
        // if (i >>> 24 == 0) { n +=  8; i <<=  8; }
        // if (i >>> 28 == 0) { n +=  4; i <<=  4; }
        // if (i >>> 30 == 0) { n +=  2; i <<=  2; }
        // n -= i >>> 31;
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
        // AppLog.error("${c}  ${t&c}  ${num}");
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
        // HD, Figure 5-2
        // i = i - ((i >>> 1) & 0x55555555);
        // i = (i & 0x33333333) + ((i >>> 2) & 0x33333333);
        // i = (i + (i >>> 4)) & 0x0f0f0f0f;
        // i = i + (i >>> 8);
        // i = i + (i >>> 16);
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

        // if (s == null) {
        //     throw new NumberFormatException("null");
        // }

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
            //var firstChar: Char = s.charAt(0);
            var firstChar: Char = s.toRuneArray()[0]
            if (firstChar < '0') { // Possible leading "+" or "-"
                if (firstChar == '-') {
                    negative = true;
                    limit = Integer.MIN_VALUE_64;
                } else if (firstChar != '+') {
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
                //digit = s.charAt(i).digit(radix);
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