/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2023-2024. All rights resvered.
 */
 
package droplet.droplet



@FastNative
foreign func malloc(size: UIntNative) : CPointer<Unit>
@FastNative
foreign func free(ptr: CPointer<Unit>): Unit
@FastNative
foreign func memcpy_s(dest:CPointer<UInt8>,destSize:UIntNative,source:CPointer<UInt8>,sourceSize:UIntNative):UIntNative

public class CommonBitmap {
  public var width: Int32 = 0
  public var height: Int32 = 0
  public var channel: Int32 = 0
  public var len: Int64 = 0
  public var data: Array<UInt8> = Array<UInt8>()
  public var data32: Array<Int32> = Array<Int32>()

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
  }

  public init(width: Int32, height: Int32, channel: Int32, path: FSPath) {
    this.width = width
    this.height = height
    this.channel = channel
    this.len = Int64(this.width * this.height * this.channel)
    this.data = Array<UInt8>(Int64(this.width * this.height * this.channel), item: 0)
    read(path)
    allocCdata()
    dataTocdata()
  }

  public init(width: Int32, height: Int32, channel: Int32, data1: Array<UInt8>) {
    this.width = width
    this.height = height
    this.channel = channel
    this.len = Int64(this.width * this.height * this.channel)
    this.data = data1
    allocCdata()
    dataTocdata()
  }

  public func read(path: FSPath) {
    var file = File(path, OpenOption.Open(true, false))
    file.read(data)
    file.close()
  }
  
  public func write(path: FSPath) {
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
        let cp = acquireArrayRawData(data)
        memcpy_s(cdata,UIntNative(data.size),cp.pointer,UIntNative(data.size))
        releaseArrayRawData(cp)
    }
  }

  public func dataTocdataCV() {
    unsafe { 
      var h = Int64(height)
      var w = Int64(width)
      var h1 = h - 1
      for (y in 0..h) {
        for (x in 0..w) {
          var i0 = y * w * 4 + x * 4
          var i1 = (h1 - y) * w * 4 + x * 4
          cdata.write(i1 + 2, data[i0])
          cdata.write(i1 + 1, data[i0 + 1])
          cdata.write(i1, data[i0 + 2])
          cdata.write(i1 + 3, data[i0 + 3])
        }
      }
    }
  }

  public func cdataToData() {
       unsafe{
           let cp = acquireArrayRawData(data)
            memcpy_s(cp.pointer,UIntNative(data.size),cdata,UIntNative(data.size))
            releaseArrayRawData(cp)
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
}