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
        

        // var ret = Array<UInt8>(m_length,item:0)
        // let bf: ByteArrayStream = ByteArrayStream()
        // bf.write(data)
        // bf.read(ret)

        // for (id in 0..m_length){
        //     ret[Int64(id)] = data[Int64(id)]
        // }
        // return ByteBuffer(ret)

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
        //var ret:Int16 =  Int16(Int16(data[m_position])) + (Int16(data[m_position+1])<<8)
        if(ByteOrder.BIG_ENDIAN==order){
            ret = Int16(Int16(data[m_position + 1])) + (Int16(data[m_position])<<8)
        }
        else{
            ret = Int16(Int16(data[m_position])) + (Int16(data[m_position+1])<<8)
        }
        //print("getShort byte1:${data[m_position]}, byte2:${data[m_position+1]}\n")
        m_position += 2;
        return ret;
    }
    public func getInt32():Int32 {  
        if (m_position + 3 >= m_length)
        {
            return 0
        }
        var ret:Int32
        //var ret:Int32 = Int32(Int32(data[m_position + 3]) << 24 | Int32(data[m_position + 2]) << 16 | Int32(data[m_position + 1]) << 8 | Int32(data[m_position]));
        if(ByteOrder.BIG_ENDIAN==order){
            ret = Int32(Int32(data[m_position ]) << 24 | Int32(data[m_position + 1]) << 16 | Int32(data[m_position + 2]) << 8 | Int32(data[m_position + 3]));
        }else{
            ret = Int32(Int32(data[m_position + 3]) << 24 | Int32(data[m_position + 2]) << 16 | Int32(data[m_position + 1]) << 8 | Int32(data[m_position]));
        }
        m_position += 4
        return ret        
    }  
    public func getData(ret:Array<UInt8>){
        // AppLog.error("getData1 : ${ret.size}")
        var len=ret.size
        //print("getData(Array<UInt8>):m_position=${m_position} len=${len}\n")

        data.copyTo(ret, m_position, 0, len)
        // for (id in 0..len){
        //     ret[Int64(id)] = data[Int64(m_position+id)]
        // }
        m_position+=len
     }
    public func getByte(): UInt8{
        //if(m_position>=m_length){
            //print("getByte(): UInt8 > m_position:${m_position}  m_length:${m_length}\n")
        //}
        var ret:UInt8 = data[m_position];
        //print("getByte:${Int32(ret)} posi:${m_position}\n")
        m_position += 1
        return ret
    }
    public func getData(ret:Array<UInt8>, n:Int32, count:Int32){
        
        var len=ret.size
        // AppLog.error("getData2: ${len}")
        
        // let now = Time.now()
        data.copyTo(ret, m_position, Int64(n), Int64(count))
        // for (id in 0..count){
        //     ret[Int64(n+id)] = data[m_position + Int64(id)]
        // }
        m_position+=Int64(count)

        // AppLog.error("time: ${Time.since(now)}")
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