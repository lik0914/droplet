package glide

public class Color{
    public static func red(val:UInt32):UInt32 {
        return (val >> 16) & 0xFF;
    }


    public static func green(val:UInt32):UInt32 {
        return (val >> 8) & 0xFF;
    }


    public static func blue(val:UInt32):UInt32 {
        return (val >> 0) & 0xFF;
    }


    public static func alpha(val:UInt32):UInt32 {
        return (val >> 24) & 0xff;
    }
    public static let TRANSPARENT:UInt32 = (0xFF >> 24)
}