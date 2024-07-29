/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2023-2024. All rights resvered.
 */
 
package droplet.droplet


public class ByteBuffer
{
    private var m_position:Int64 = 0
    private var m_length:Int64 = 0
    private var data:Array<UInt8> = Array<UInt8>();
    private var order:ByteOrder = ByteOrder.BIG_ENDIAN

    public init() {
        m_position = 0
    }
    public init(in_data:Array<UInt8>) {
        m_length = in_data.size
        m_position = 0
        data = in_data 
    }
    public func setOrder(order1:ByteOrder){
        order=order1
    }
    public func getOrder():ByteOrder{
        return order
    }
    public func setPosition(posi:Int32):Unit {
        m_position = Int64(posi)
    }
    public func getPosition():Int32{
        return Int32(m_position)
    }
    public func asReadOnlyBuffer():ByteBuffer{
        return ByteBuffer(data.clone())
    }
    public static func wrap(data:Array<UInt8>):ByteBuffer{
        return ByteBuffer(data);
    }
    public func isEmpty():Bool{
        return data.isEmpty()
    }
    public func limit():Int32{
        return Int32(m_length) 
    }
    public func getShort():Int16 {
        if (m_position  + 1 >= m_length)
        {
            return 0;
        }
        var ret:Int16
        if(ByteOrder.BIG_ENDIAN==order){
            ret = Int16(Int16(data[m_position + 1])) + (Int16(data[m_position])<<8)
        }
        else{
            ret = Int16(Int16(data[m_position])) + (Int16(data[m_position+1])<<8)
        }
        m_position += 2;
        return ret;
    }
    public func getInt32():Int32 {  
        if (m_position + 3 >= m_length)
        {
            return 0
        }
        var ret:Int32
        if(ByteOrder.BIG_ENDIAN==order){
            ret = Int32(Int32(data[m_position ]) << 24 | Int32(data[m_position + 1]) << 16 | Int32(data[m_position + 2]) << 8 | Int32(data[m_position + 3]));
        }else{
            ret = Int32(Int32(data[m_position + 3]) << 24 | Int32(data[m_position + 2]) << 16 | Int32(data[m_position + 1]) << 8 | Int32(data[m_position]));
        }
        m_position += 4
        return ret        
    }  
    public func getData(ret:Array<UInt8>){
        var len=ret.size
        data.copyTo(ret, m_position, 0, len)
        m_position+=len
     }
    public func getByte(): UInt8{
        var ret:UInt8 = data[m_position];
        m_position += 1
        return ret
    }
    public func getData(ret:Array<UInt8>, n:Int32, count:Int32){
        
        var len=ret.size
        data.copyTo(ret, m_position, Int64(n), Int64(count))
        m_position+=Int64(count)
    }

    public func put(indata:UInt8):ByteBuffer {
        data[m_position] = indata;
        m_position++
        return this
    }
    public func put(Num:UInt16):ByteBuffer{
        if(ByteOrder.BIG_ENDIAN==order){        
            data[m_position] = UInt8(((Num & 0xff00) >> 8) & 0xff);
            m_position+=1
            data[m_position] = UInt8((Num & 0x00ff) & 0xff);
            m_position+=1
        }else{
            data[m_position] = UInt8((Num & 0x00ff) & 0xff);
            m_position+=1
            data[m_position] = UInt8(((Num & 0xff00) >> 8) & 0xff);
            m_position+=1
        }
        return this
    }
    public func put(Num:UInt32):ByteBuffer
    {
        if(ByteOrder.BIG_ENDIAN==order){     
            data[m_position] = UInt8(((Num & 0xff000000) >> 24) & 0xff);
            m_position+=1
            data[m_position] = UInt8(((Num & 0x00ff0000) >> 16) & 0xff);
            m_position+=1
            data[m_position] = UInt8(((Num & 0x0000ff00) >> 8) & 0xff);
            m_position+=1
            data[m_position] = UInt8((Num & 0x000000ff) & 0xff);
            m_position+=1
        }
        else
        {
            data[m_position] = UInt8((Num & 0x000000ff) & 0xff);
            m_position+=1
            data[m_position] = UInt8(((Num & 0x0000ff00) >> 8) & 0xff);
            m_position+=1
            data[m_position] = UInt8(((Num & 0x00ff0000) >> 16) & 0xff);
            m_position+=1
            data[m_position] = UInt8(((Num & 0xff000000) >> 24) & 0xff);
            m_position+=1           
        }
        return this
    }

    @OverflowWrapping
    public func put(Num:Int32):ByteBuffer
    {
        if(ByteOrder.BIG_ENDIAN==order){     
            data[m_position] = UInt8(((Num & Int32(0xff000000)) >> 24) & 0xff);
            m_position+=1
            data[m_position] = UInt8(((Num & 0x00ff0000) >> 16) & 0xff);
            m_position+=1
            data[m_position] = UInt8(((Num & 0x0000ff00) >> 8) & 0xff);
            m_position+=1
            data[m_position] = UInt8((Num & 0x000000ff) & 0xff);
            m_position+=1
        }else{
            data[m_position] = UInt8((Num & 0x000000ff) & 0xff);
            m_position+=1
            data[m_position] = UInt8(((Num & 0x0000ff00) >> 8) & 0xff);
            m_position+=1
            data[m_position] = UInt8(((Num & 0x00ff0000) >> 16) & 0xff);
            m_position+=1
            data[m_position] = UInt8(((Num & Int32(0xff000000)) >> 24) & 0xff);
            m_position+=1            
        }
        return this
    }

    public func remaining():Int32 {
        return Int32(m_length - m_position)
    }
    public func array():Array<UInt8> {
        return data
    }
    public static func allocate(len:Int64):ByteBuffer{
        return ByteBuffer(Array<UInt8>(len,item:0))
    }
    public func printHex(){
        print("ByteBuffer printHex: ${toHexString(data)}\n")
    }
}