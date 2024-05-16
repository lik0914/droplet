package glide.util.utils

from std import collection.*
from std import io.*
from std import fs.*
from std import sync.*

public class Utils {
    private static let HASH_MULTIPLIER: Int64 = 31
    private static let HASH_ACCUMULATOR: Int64 = 17
    private static var hasher: DefaultHasher = DefaultHasher()

    // public static func hashCode(value: Int64, accumulator: Int64) {
    //     // return (accumulator * HASH_MULTIPLIER) + value
    //     hasher.reset()
    //     hasher.write(value)
    //     return hasher.finish()
    // }

    public static func hashCode<V>(values: Array<V>) where V <: Hashable {
        hasher.reset()
        for(o in values) {
            hasher.write(o.hashCode())
        }
        return hasher.finish()
    }

    public static func hashCodeWrite(value: UInt32, reset!: Bool = false) {
        if(reset) {
            hasher.reset()
        }
        hasher.write(value)
    }

    public static func hashCodeWrite<V>(values: Array<V>, reset!: Bool = false) where V <: Hashable {
        if(reset) {
            hasher.reset()
        }
        for(o in values) {
            hasher.write(o.hashCode())
        }
    }

    public static func hashCodeWrite(value: Int64, reset!: Bool = false) {
        if(reset) {
            hasher.reset()
        }
        hasher.write(value)
    }

    public static func hashCodeWrite(value: String, reset!: Bool = false) {
        if(reset) {
            hasher.reset()
        }
        hasher.write(value)
    }

    public static func hashCodeReset(): Unit {
        hasher.reset()
    }

    public static func hashCodeFinish(): Int64 {
        return hasher.finish()
    }

    public static func hashCode(value: Int64) {
        // return hashCode(value, HASH_ACCUMULATOR)
        hasher.reset()
        hasher.write(value)
        return hasher.finish()
    }

    public static func hashCode(value: Float32) {
        hasher.reset()
        hasher.write(value)
        return hasher.finish()
    }

    public static func setStringBuilderLength(sb: StringBuilder, length: Int64): StringBuilder {
        var size: Int64 = sb.size
        if (size > length) {
            let r: Range<Int64> = length .. size - length 

            //适配
            //sb.remove(r)
            var strTemp = sb.toString()
            let r2: Range<Int64> = 0 .. length
            var subStrTemp = strTemp[r2]
            return StringBuilder(subStrTemp)
        } else {
            return sb
        }
    }

    /**
    * Returns {@code true} if {@code width} and {@code height} are both {@code > 0} and/or equal to
    * {@link Target#SIZE_ORIGINAL}.
    */
    public static func isValidDimensions(width: Int64, height: Int64): Bool {
        return isValidDimension(width) && isValidDimension(height);
    }

    public static func isValidDimension(dimen: Int64): Bool {
        return dimen > 0 || dimen == -0x7FFFFFFFFFFFFFFF;
    }

    public static func optionEquals<T>(o1: Option<T>, o2: Option<T>): Bool where T <: Equatable<T> {
        if(match(o1) {
            case Some(x) => false
            case _ => true
        }) {
            if(match(o2) {
                case Some(x) => false
                case _ => true
            }) {
                return true
            } else {
                return false
            }
        } else {
            if(match(o2) {
                case Some(x) => false
                case _ => true
            }) {
                return false
            } else {
                return o1.getOrThrow() == o2.getOrThrow()
            }
        }

        return false
    }

    public static func optionEqualsNotSame<T, T2>(o1: Option<T>, o2: Option<T2>): Bool where T <: Equatable<T> {
        if(match(o1) {
            case Some(x) => false
            case _ => true
        }) {
            if(match(o2) {
                case Some(x) => false
                case _ => true
            }) {
                return true
            } else {
                return false
            }
        } else {
            if(match(o2) {
                case Some(x) => false
                case _ => true
            }) {
                return false
            } else {
                let o3: T2 = o2.getOrThrow()
                if(o3 is T) {
                    return o1.getOrThrow() == (o3 as T).getOrThrow()
                }
                return false
                
            }
        }

        return false
    }

    public static func getRequestManagerKey(key: String): String {
        return "manager${key}"
    }

    public static func getSnapshot<T>(other: HashSet<T>): ArrayList<T> where T <: Hashable & Equatable<T> {
        let result: ArrayList<T> = ArrayList<T>();
        for (item in other) {
            result.append(item);
        }
        return result;
    }

    public static func arrU32ToU8(arrU32: Array<UInt32>): Array<UInt8> {
        let arrU8 = ArrayList<UInt8>()
        for(a in arrU32) {
            arrU8.append(UInt8(a))
        }
        return arrU8.toArray()
    }

    public static func arrU8ToU32(arrU8: Array<UInt8>): Array<UInt32> {
        let arrU32 = ArrayList<UInt32>()
        var i: Int64 = 0
        while(i < arrU8.size) {
            arrU32.append(UInt32(arrU8[i]))
            i++
        }
        return arrU32.toArray()
    }

    // public static func arrU32ToU8(arrU32: Array<UInt32>): Array<UInt8> {
    //     let arrU8 = ArrayList<UInt8>()
    //     for(arr in arrU32) {
    //         arrU8.append(UInt8((arr & 0xFF000000) >> 24))
    //         arrU8.append(UInt8((arr & 0x00FF0000) >> 16))
    //         arrU8.append(UInt8((arr & 0x0000FF00) >> 8))
    //         arrU8.append(UInt8((arr & 0x000000FF)))
    //     }
    //     return arrU8.toArray()
    // }

    // public static func arrU8ToU32(arrU8: Array<UInt8>): Array<UInt32> {
    //     let arrU32 = ArrayList<UInt32>()
    //     var i: Int64 = 0
    //     while(i < arrU8.size) {
    //         let a = UInt32(UInt32(arrU8[i]) << 24)
    //         i++
    //         let r = UInt32(UInt32(arrU8[i]) << 16)
    //         i++
    //         let g = UInt32(UInt32(arrU8[i]) << 8)
    //         i++
    //         let b = UInt32(arrU8[i])
    //         i++
    //         arrU32.append(a | r | g | b)
    //     }
    //     return arrU32.toArray()
    // }
}
