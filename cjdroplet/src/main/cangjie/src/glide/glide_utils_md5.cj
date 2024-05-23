package glide

from std import format.Formatter
from std import overflow.*

public class MD5 <: ToString {
    // public staticvar test_data:Array<String> = [
    //     "",	
    //     "a",
    //     "abc",
    //     "message digest",
    //     "abcdefghijklmnopqrstuvwxyz",
	//     "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789",
    //     "12345678901234567890123456789012345678901234567890123456789012345678901234567890",
    //     "1234567890123456789012345678901234567890123456789012345678901234"]
// abcdefghijklmnopqrstuvwxyz~!"':;<>?abcdefghijklmnopqrstuvwxyz~!"':;<>?
    // public staticvar test_result:Array<String> = [
    //     "d41d8cd98f00b204e9800998ecf8427e",
    //     "0cc175b9c0f1b6a831c399e269772661",
    //     "900150983cd24fb0d6963f7d28e17f72",
    //     "f96b697d7cb7938d525a2f31aaf161d0",
    //     "c3fcd3d76192e4007dfb496cca67e13b",
    //     "d174ab98d277d9f5a5611c2c9f419d9f",
    //     "57edf4a22be3c955ac49da2e2107b67a",
    //     "EB6C4179C0A7C82CC2828C1E6338E165"]

    public static func InitDigest(digest : Array<UInt32>)
    {
        digest[0]=0x67452301
        digest[1]=0xEFCDAB89
        digest[2]=0x98BADCFE
        digest[3]=0x10325476
    }
    private static func rotlFixed(x: UInt32, y: UInt32): UInt32 {
        ((x << y) | (x >> (32 - y)))
    }
    private static func F1(x: UInt32, y: UInt32, z: UInt32): UInt32 {
        //(z ^ (x & (y ^ z)))
        ((x & y) | (!x & z))
    }
    private static func F2(x: UInt32, y: UInt32, z: UInt32): UInt32 {
        F1(z, x, y)
    }
    private static func F3(x: UInt32, y: UInt32, z: UInt32): UInt32 {
        (x ^ y ^ z)
    }
    private static func F4(x: UInt32, y: UInt32, z: UInt32): UInt32 {
        (y ^ (x | (!z)))
    }
    @OverflowWrapping
    private static func MD5STEP_F1(w: UInt32, x: UInt32, y: UInt32, z: UInt32, data: UInt32, s: UInt32): UInt32 {
        var ret: UInt32 = w + F1(x, y, z) + data
        ret = x + rotlFixed(ret, s) 
        return ret
    }
    @OverflowWrapping
    private static func MD5STEP_F2(w: UInt32, x: UInt32, y: UInt32, z: UInt32, data: UInt32, s: UInt32): UInt32 {
        var ret: UInt32 = w + F2(x, y, z) + data
        ret = x + rotlFixed(ret, s) 
        return ret
    }
    @OverflowWrapping
    private static func MD5STEP_F3(w: UInt32, x: UInt32, y: UInt32, z: UInt32, data: UInt32, s: UInt32): UInt32 {
        var ret: UInt32 = w + F3(x, y, z) + data 
        ret = x + rotlFixed(ret, s) 
        return ret
    }   
    @OverflowWrapping
    private static func MD5STEP_F4(w: UInt32, x: UInt32, y: UInt32, z: UInt32, data: UInt32, s: UInt32): UInt32 {
        var ret: UInt32 = w + F4(x, y, z) + data 
        ret = x + rotlFixed(ret, s) 
        return ret
    } 
    public static func ToUInt8 (digest: Array<UInt32>):Array<UInt8>{
        var ret:Array<UInt8> = Array<UInt8>(16,item:0);    
        for (j in 0..4) {
            ret[j] = UInt8((digest[0] >> (j * 8)) & 0x000000ff)
            ret[j + 4] = UInt8((digest[1] >> (j * 8)) & 0x000000ff)
            ret[j + 8] = UInt8((digest[2] >> (j * 8)) & 0x000000ff)
            ret[j + 12] = UInt8((digest[3] >> (j * 8)) & 0x000000ff)
        }
        return ret
    }
    public static func ToString(data: Array<UInt8>): String {
        var str = ""
        for (a in data) {
            str += a.format("02X")
        }
        return str
    }
    @OverflowWrapping
    public static func Transform (digest: Array<UInt32>, data : Array<UInt8>){
        var count: Int64 = 0
        var data_in: Array<UInt32> = Array<UInt32>(16, item:0)
        for (i in 0..16) {
            data_in[i] = UInt32(data[count]) + 
                (UInt32(data[count + 1]) << 8) + 
                (UInt32(data[count + 2]) << 16) + 
                (UInt32(data[count + 3]) << 24)
            count += 4
        } 
        Transform(digest, data_in);
    }

    @OverflowWrapping
    public static func Transform (digest: Array<UInt32>, data : Array<UInt32>)
    {
        var a: UInt32 = digest[0]
        var b: UInt32 = digest[1]
        var c: UInt32 = digest[2]
        var d: UInt32 = digest[3]        
        
        a = MD5STEP_F1(a, b, c, d, data[0] + 0xd76aa478, 7);
        d = MD5STEP_F1(d, a, b, c, data[1] + 0xe8c7b756, 12);
        c = MD5STEP_F1(c, d, a, b, data[2] + 0x242070db, 17);
        b = MD5STEP_F1(b, c, d, a, data[3] + 0xc1bdceee, 22);
        a = MD5STEP_F1(a, b, c, d, data[4] + 0xf57c0faf, 7);
        d = MD5STEP_F1(d, a, b, c, data[5] + 0x4787c62a, 12);
        c = MD5STEP_F1(c, d, a, b, data[6] + 0xa8304613, 17);
        b = MD5STEP_F1(b, c, d, a, data[7] + 0xfd469501, 22);
        a = MD5STEP_F1(a, b, c, d, data[8] + 0x698098d8, 7);
        d = MD5STEP_F1(d, a, b, c, data[9] + 0x8b44f7af, 12);
        c = MD5STEP_F1(c, d, a, b, data[10] + 0xffff5bb1, 17);
        b = MD5STEP_F1(b, c, d, a, data[11] + 0x895cd7be, 22);
        a = MD5STEP_F1(a, b, c, d, data[12] + 0x6b901122, 7);
        d = MD5STEP_F1(d, a, b, c, data[13] + 0xfd987193, 12);
        c = MD5STEP_F1(c, d, a, b, data[14] + 0xa679438e, 17);
        b = MD5STEP_F1(b, c, d, a, data[15] + 0x49b40821, 22);

        a = MD5STEP_F2(a, b, c, d, data[1] + 0xf61e2562, 5);
        d = MD5STEP_F2(d, a, b, c, data[6] + 0xc040b340, 9);
        c = MD5STEP_F2(c, d, a, b, data[11] + 0x265e5a51, 14);
        b = MD5STEP_F2(b, c, d, a, data[0] + 0xe9b6c7aa, 20);
        a = MD5STEP_F2(a, b, c, d, data[5] + 0xd62f105d, 5);
        d = MD5STEP_F2(d, a, b, c, data[10] + 0x02441453, 9);
        c = MD5STEP_F2(c, d, a, b, data[15] + 0xd8a1e681, 14);
        b = MD5STEP_F2(b, c, d, a, data[4] + 0xe7d3fbc8, 20);
        a = MD5STEP_F2(a, b, c, d, data[9] + 0x21e1cde6, 5);
        d = MD5STEP_F2(d, a, b, c, data[14] + 0xc33707d6, 9);
        c = MD5STEP_F2(c, d, a, b, data[3] + 0xf4d50d87, 14);
        b = MD5STEP_F2(b, c, d, a, data[8] + 0x455a14ed, 20);
        a = MD5STEP_F2(a, b, c, d, data[13] + 0xa9e3e905, 5);
        d = MD5STEP_F2(d, a, b, c, data[2] + 0xfcefa3f8, 9);
        c = MD5STEP_F2(c, d, a, b, data[7] + 0x676f02d9, 14);
        b = MD5STEP_F2(b, c, d, a, data[12] + 0x8d2a4c8a, 20);

        a = MD5STEP_F3(a, b, c, d, data[5] + 0xfffa3942, 4);
        d = MD5STEP_F3(d, a, b, c, data[8] + 0x8771f681, 11);
        c = MD5STEP_F3(c, d, a, b, data[11] + 0x6d9d6122, 16);
        b = MD5STEP_F3(b, c, d, a, data[14] + 0xfde5380c, 23);
        a = MD5STEP_F3(a, b, c, d, data[1] + 0xa4beea44, 4);
        d = MD5STEP_F3(d, a, b, c, data[4] + 0x4bdecfa9, 11);
        c = MD5STEP_F3(c, d, a, b, data[7] + 0xf6bb4b60, 16);
        b = MD5STEP_F3(b, c, d, a, data[10] + 0xbebfbc70, 23);
        a = MD5STEP_F3(a, b, c, d, data[13] + 0x289b7ec6, 4);
        d = MD5STEP_F3(d, a, b, c, data[0] + 0xeaa127fa, 11);
        c = MD5STEP_F3(c, d, a, b, data[3] + 0xd4ef3085, 16);
        b = MD5STEP_F3(b, c, d, a, data[6] + 0x04881d05, 23);
        a = MD5STEP_F3(a, b, c, d, data[9] + 0xd9d4d039, 4);
        d = MD5STEP_F3(d, a, b, c, data[12] + 0xe6db99e5, 11);
        c = MD5STEP_F3(c, d, a, b, data[15] + 0x1fa27cf8, 16);
        b = MD5STEP_F3(b, c, d, a, data[2] + 0xc4ac5665, 23);

        a = MD5STEP_F4(a, b, c, d, data[0] + 0xf4292244, 6);
        d = MD5STEP_F4(d, a, b, c, data[7] + 0x432aff97, 10);
        c = MD5STEP_F4(c, d, a, b, data[14] + 0xab9423a7, 15);
        b = MD5STEP_F4(b, c, d, a, data[5] + 0xfc93a039, 21);
        a = MD5STEP_F4(a, b, c, d, data[12] + 0x655b59c3, 6);
        d = MD5STEP_F4(d, a, b, c, data[3] + 0x8f0ccc92, 10);
        c = MD5STEP_F4(c, d, a, b, data[10] + 0xffeff47d, 15);
        b = MD5STEP_F4(b, c, d, a, data[1] + 0x85845dd1, 21);
        a = MD5STEP_F4(a, b, c, d, data[8] + 0x6fa87e4f, 6);
        d = MD5STEP_F4(d, a, b, c, data[15] + 0xfe2ce6e0, 10);
        c = MD5STEP_F4(c, d, a, b, data[6] + 0xa3014314, 15);
        b = MD5STEP_F4(b, c, d, a, data[13] + 0x4e0811a1, 21);
        a = MD5STEP_F4(a, b, c, d, data[4] + 0xf7537e82, 6);
        d = MD5STEP_F4(d, a, b, c, data[11] + 0xbd3af235, 10);
        c = MD5STEP_F4(c, d, a, b, data[2] + 0x2ad7d2bb, 15);
        b = MD5STEP_F4(b, c, d, a, data[9] + 0xeb86d391, 21);

        digest[0]+=a;
        digest[1]+=b;
        digest[2]+=c;
        digest[3]+=d;
    }
    private var m_digest: Array<UInt32> =[0,0,0,0]
    private var m_len0:Int64 = 0
    private var m_len1:UInt64 = 0
    private var m_data: Array<UInt8> = Array<UInt8>(64, item:0)
    private var m_fill: Array<UInt8> = Array<UInt8>(65, item:0)
    public init(){
        m_fill[0]=0x80;
        MD5Init();
    }  
    public func MD5Init(){
        MD5.InitDigest(m_digest);
        m_len0 = 0
        m_len1 = 0;
    }
    @OverflowWrapping 
    public func MD5Update(data: Array<UInt8>) {
        return MD5Update(data, data.size)
    }
    @OverflowWrapping
    public func MD5Update(data: Array<UInt8>, len: Int64) {
        m_len1+=UInt64(len)
        var count_pre:Int64 = 64 - m_len0;
        var processed:Int64 = 0;
        if( m_len0 > 0 ){
            if(len >= count_pre){
                data.copyTo(this.m_data, 0, m_len0, count_pre)
                Transform(this.m_digest,this.m_data);
                processed = count_pre;
                this.m_len0 = 0;
            }
            else
            {
                data.copyTo(this.m_data, 0, m_len0, len)
                this.m_len0 = m_len0+ len
                return
            }
        }

        var count64:Int64 = (len - processed) / 64
        for (i in 0..count64) {
            data.copyTo(this.m_data, i * 64 + processed, 0, 64)
            Transform(this.m_digest,this.m_data);
        }
        this.m_len0 = (len - processed) % 64
        if(this.m_len0>0){
            data.copyTo(m_data, len - m_len0 ,0 , m_len0);
        }
    }
    @OverflowWrapping
    public func MD5Final() {
        var fill_len = 64-m_len0;
        m_fill.copyTo(this.m_data, 0, m_len0, fill_len);
        if(m_len0>56){
            Transform(this.m_digest,this.m_data);
            m_fill.copyTo(this.m_data, 1, 0, 56);
        }
        m_len1 = m_len1 * 8
        m_data[56] = UInt8(m_len1)
        m_data[57] = UInt8(m_len1 >> 8)
        m_data[58] = UInt8(m_len1 >> 16)
        m_data[59] = UInt8(m_len1 >> 24)
        m_data[60] = UInt8(m_len1 >> 32)
        m_data[61] = UInt8(m_len1 >> 40)
        m_data[62] = UInt8(m_len1 >> 48)
        m_data[63] = UInt8(m_len1 >> 56)      
        Transform(this.m_digest,this.m_data);
    }
    public func toString(): String {
        var bytes:Array<UInt8> = ToUInt8(m_digest);
        var str = ""
        for (a in bytes) {
            str += a.format("02x")
        }
        return str
    }
    public func toUInt8Array(): Array<UInt8> {
        return ToUInt8(m_digest);
    }
    
    public func getStringValue(): String {
        MD5Final()
        var str = toString()
        MD5Init()
        return str
    }
}
/*
main(): Int64 {
    print("hello MD5\n")

    for(i in 0..7){
        AppLog.error(MD5.test_data[i].toUtf8Array())
        AppLog.error(MD5.test_data[i])
        AppLog.error("DATA:"+MD5.test_result[i])
        var md5 = MD5();  //create object
        md5.MD5Init()  //Init md5 digest
        md5.MD5Update(MD5.test_data[i].toUtf8Array(),MD5.test_data[i].toUtf8Array().size)  //update data
        md5.MD5Update("123456".toUtf8Array(),6)

        md5.MD5Final()  // finish md5
        AppLog.error("RESU:"+md5.toString())   //get md5 string
    }
    return 0
    
}
*/