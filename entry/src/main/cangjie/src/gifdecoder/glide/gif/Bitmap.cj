package gifdecoder.glide.gif

foreign func malloc(size: UIntNative) : CPointer<Unit>
foreign func free(ptr: CPointer<Unit>): Unit

public class Bitmap {
  public var width: Int32 = 0
  public var height: Int32 = 0
  public var channel: Int32 = 0
  public var len: Int64 = 0
  public var data: Array<UInt8> = Array<UInt8>()
  public var data32: Array<UInt32> = Array<UInt32>()

  public var ptr: CPointer<Unit> = CPointer<Unit>()
  public var cdata: CPointer<UInt8> = CPointer<UInt8>()

  public init() {
    this.width = 0
    this.height = 0
    this.channel = 0
    this.data = Array<UInt8>()
  }

  public init(width: Int32, height: Int32, channel: Int32) {
    this.width = width
    this.height = height
    this.channel = channel
    this.len = Int64(this.width * this.height * this.channel)
    this.data = Array<UInt8>(Int64(this.width * this.height * this.channel), item: 0)
    this.data32 = Array<UInt32>(Int64(this.width * this.height), item: 0)
  }

  public init(width: Int32, height: Int32, channel: Int32, path: fs.Path) {
    this.width = width
    this.height = height
    this.channel = channel
    this.len = Int64(this.width * this.height * this.channel)
   
    this.data = Array<UInt8>(Int64(this.width * this.height * this.channel), item: 0)
    this.data32 = Array<UInt32>(Int64(this.width * this.height), item: 0)
    read(path)
    allocCdata()
    dataTocdata()
  }
  public init(bm:Bitmap ){
    this.width = bm.width
    this.height = bm.height
    this.channel = bm.channel
    this.len = bm.len
    this.data = Array<UInt8>(Int64(this.width * this.height * this.channel), item: 0)
    bm.data.copyTo(this.data, 0, 0, this.data.size)
    this.data32 = Array<UInt32>(Int64(this.width * this.height), item: 0)
    bm.data32.copyTo(this.data32, 0, 0, this.data32.size)   
    //print("this.data ${data[0]}  ${data[1]} ${data[2]} ${data[3]} ${data[4]} ${data[5]} ${data[6]}  ${data[6]} ${data[8]} ${data[9]} ${data[10]} ${data[11]}\n")
    //print("this.data32 ${data32[0]}  ${data32[1]} ${data32[2]} ${data32[3]} ${data32[4]} ${data32[5]}\n")
  }
  public init(width: Int32, height: Int32, channel: Int32, data: Array<UInt8>) {
    this.width = width
    this.height = height
    this.channel = channel
    this.len = Int64(this.width * this.height * this.channel)
    this.data = Array<UInt8>(data)
    allocCdata()
    dataTocdata()
  }
  public func getWidth():Int32{
    return width
  }
  public func getHeight():Int32{
    return height
  }
  public static func createBitmap(width:Int32, height:Int32, config:Bitmap_Config):Bitmap{
    //print("static func createBitmap  Bitmap_Config:${config.GetTypeNum(config)}\n")
    if(config==Bitmap_Config.ARGB_8888){
      return Bitmap(width, height,4)
    } else {
      throw Exception("Only support Bitmap_Config.ARGB_8888!")
    }
  }
  public func read(path: fs.Path) {
    var file = File(path, OpenOption.Open(true, false))
    // AppLog.error("file len is ${file.length}, data len is ${data.size}")

    file.read(data)
    file.close()
  }
  
  public func write(path: fs.Path) {
    var file: File = File(path, OpenOption.CreateOrTruncate(false))
    file.write(data)
    file.close()
  }

  public func allocCdata() {

    ptr = unsafe { malloc(UIntNative(len)) }
    cdata = unsafe { CPointer<UInt8>(ptr) }
  }

  public func dataTocdata() {
    unsafe { 
      for (i in 0..len) {
        cdata.write(i, data[i])
      }
    }
  }

  public func cdataToData() {
    for (i in 0..len) {
      data[i] = unsafe { cdata.read(i) }
    }
  }

  public func release() {
    unsafe { free(ptr) }
  }

  public func at(y: Int32, x: Int32, ch: Int32): UInt8 {
    let idx = Int64(y * width * channel + x * channel + ch)
    return data[idx]
  }

  public func set(y: Int32, x: Int32, ch: Int32, value: UInt8) {
    let idx = Int64(y * width * channel + x * channel + ch)
    data[idx] = value
  }

  public func dataTodata32() {
    //channel should be 3.
    data32 = Array<UInt32>(Int64(width * height), item: 0)
    for (y in 0..height) {
      let yw = y * width
      for (x in 0..width) {
        var red = UInt32(UInt32(this.at(y, x, 0)) << 16)
        var green = UInt32(UInt32(this.at(y, x, 1)) << 8)
        var blue = UInt32(UInt32(this.at(y, x, 2)))
        data32[Int64(yw + x)] = red | green | blue
        // AppLog.error("${data32[Int64(yw + x)]}, ${red}, ${green}, ${blue}")
      }
    }
  }
  public func data32Todata() {
    //channel should be 3.
    //print("data32todata data32 size=${data32.size} width=${width}, height=${height}, channel=${channel}\n")
    data = Array<UInt8>(Int64(width * height * channel), item: 0)
    for (y in 0..height) {
      let yw = y * width
      for (x in 0..width) {
        var p = data32[Int64(yw + x)]
        this.set(y, x, 0, UInt8((p & 0xff0000) >> 16))
        this.set(y, x, 1, UInt8((p & 0x00ff00) >> 8))
        this.set(y, x, 2, UInt8((p & 0x0000ff)))
      }
    }
  }
  public func getPixel (x:Int32, y:Int32):UInt32{
    return data32[Int64(this.width * y + x)]
  }
  public func getPixels (pixels:Array<UInt32>, offset:Int32,stride:Int32, x:Int32, y:Int32, width:Int32, height:Int32):Unit
  {
    var outpos:Int64 = Int64(offset) 
    var times:Int32 = 0
    for(yid in 0..height){
      if(stride >= width){
        times=width
      }else{
        times=stride
      }
      for(xid in 0..times){
          pixels[outpos+Int64(xid)]=data32[Int64(this.width * yid + xid)]
      }
      outpos += Int64(stride)
    }
    //print(data)
  }

  public func setPixels (pixels:Array<UInt32>, offset:Int32, stride:Int32, x:Int32, y:Int32, width:Int32, height:Int32):Unit{
    //print("setPixels  offset:${offset}, stride:${stride}, x:${x}, y:${y}, width:${width}, height:${height}\n")
    var outpos:Int64 = Int64(offset) 
    var times:Int32 = 0
    for(yid in 0..height){
      if(stride >= width){
        times=width
      }else{
        times=stride
      }
      for(xid in 0..times){
        data32[Int64(this.width * yid + xid)] = pixels[outpos+Int64(xid)]
      }
      outpos += Int64(stride)
    }
    //print("${data32}\n")
    data32Todata()
  }
  public func getData32():Array<UInt32>{
    return data32
  }
  public func getData():Array<UInt8>{
    return data
  }

  private var hasApha=false
  public func setHasAlpha(val:Bool) {
    hasApha =val
  }
  public var Config =  Bitmap_Config.RGB_888
}
  public enum Bitmap_Config <: Hashable & Equatable<Bitmap_Config>{ 
    |RGB_888
    |ARGB_8888
    |RGB_565
    public func GetTypeNum(result: Bitmap_Config): Int64 {
        match (result) {
            case RGB_888 => return 0
            case ARGB_8888 => return 1
            case RGB_565 => return 2
        }
    }    
    public operator func ==(right: Bitmap_Config): Bool {
      if(GetTypeNum(right) == GetTypeNum(this)){ 
        true;
      } else {
        false;
      }
    }
    public operator func !=(right: Bitmap_Config): Bool {
      if (GetTypeNum(right) != GetTypeNum(this)){
        true ;
      } else {
        false 
      }
    } 
    public func hashCode(): Int64 {
        return GetTypeNum(this);
    }      
  }
