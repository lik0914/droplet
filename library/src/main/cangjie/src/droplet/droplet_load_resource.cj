/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2023-2024. All rights resvered.
 */
 
package droplet.droplet



public class PixelMapDrawableResource <: DropletResource<PixelMapDrawable> {
    private var pixelMapDrawable: PixelMapDrawable

    public static func obtain(pixelMapDrawable: PixelMapDrawable): PixelMapDrawableResource {
        return PixelMapDrawableResource(pixelMapDrawable);
    }

    public override func getResourceTypeClass(): ResourceTypeClass {
        return ResourceTypeClass.RESOURCE_TYPE_PIXELMAP
    }

    public override func get(): PixelMapDrawable {
        return pixelMapDrawable;
    }

    public override func getAsAny(): Any {
        return (pixelMapDrawable as Any).getOrThrow()
    }

    public override func getSize(): Int32 {
        let pixelMap: PixelMap = pixelMapDrawable.getPixelMap()
        return Int32(pixelMap.getPixelBytesNumber())
    }

    public override func recycle(): Unit {
    }

    public init(pixelMapDrawable: PixelMapDrawable) {
        this.pixelMapDrawable = pixelMapDrawable
    }

    public func toString(): String {
        // TODO PixelMap toString
        return "pixelMapDrawableResource"
    }

    public func hashCode(): Int64 {
        // TODO PixelMap hashCode
        return 0
    }

    public operator func ==(that: AnyDropletResource): Bool {
        // TODO PixelMap ==
        if (that is DropletResource<PixelMapDrawable>) {
            return true
        }
        return false
    }

    public operator func !=(that: AnyDropletResource): Bool {
        // TODO PixelMap !=
        if (that is DropletResource<PixelMapDrawable>) {
            return false
        }
        return true
    }

    public func copy(): DropletResource<PixelMapDrawable> {
        return this
    }
}

public class PixelMapResource <: DropletResource<PixelMap> {
    private var pixelMap: PixelMap

    public static func obtain(pixelMap: PixelMap): PixelMapResource {
        return PixelMapResource(pixelMap);
    }

    public override func getResourceTypeClass(): ResourceTypeClass {
        return ResourceTypeClass.RESOURCE_TYPE_PIXELMAP
    }

    public override func get(): PixelMap {
        return pixelMap;
    }

    public override func getAsAny(): Any {
        return (pixelMap as Any).getOrThrow()
    }

    public override func getSize(): Int32 {
        // TODO PixelMap getSize
        return Int32(pixelMap.getPixelBytesNumber())
    }

    public override func recycle(): Unit {
    }

    public init(pixelMap: PixelMap) {
        this.pixelMap = pixelMap
    }

    public func toString(): String {
        // TODO PixelMap toString
        return "pixelMapResource"
    }

    public func hashCode(): Int64 {
        // TODO PixelMap hashCode
        return 0
    }

    public operator func ==(that: AnyDropletResource): Bool {
        // TODO PixelMap ==
        if (that is DropletResource<PixelMap>) {
            return true
        }
        return false
    }

    public operator func !=(that: AnyDropletResource): Bool {
        // TODO PixelMap !=
        if (that is DropletResource<PixelMap>) {
            return false
        }
        return true
    }

    public func copy(): DropletResource<PixelMap> {
        return this
    }
}

public class InputStreamResource <: DropletResource<InputStream> {
    private var inputStream: InputStream

    public static func obtain(inputStream: InputStream): InputStreamResource {
        return InputStreamResource(inputStream);
    }

    public override func getResourceTypeClass(): ResourceTypeClass {
        return ResourceTypeClass.RESOURCE_TYPE_INPUTSTREAM
    }

    public override func get(): InputStream {
        return inputStream;
    }

    public override func getAsAny(): Any {
        return (inputStream as Any).getOrThrow()
    }

    public override func getSize(): Int32 {
        var size = match (inputStream as Seekable) {
            case Some(v) => v.length
            case None => 0
        }
        return Int32(size)
    }

    public override func recycle(): Unit {
    }

    public init(inputStream: InputStream) {
        this.inputStream = inputStream
    }

    public func toString(): String {
        // TODO InputStreamResource toString
        return "inputStreamResource"
    }

    public func hashCode(): Int64 {
        // TODO InputStreamResource hashCode
        return 0
    }

    public operator func ==(that: AnyDropletResource): Bool {
        // TODO InputStreamResource ==
        if (that is DropletResource<InputStream>) {
            return true
        }
        return false
    }

    public operator func !=(that: AnyDropletResource): Bool {
        // TODO InputStreamResource !=
        if (that is DropletResource<InputStream>) {
            return false
        }
        return true
    }

    public func copy(): DropletResource<InputStream> {
        if (inputStream is ByteArrayStream) {
            return InputStreamResource((inputStream as ByteArrayStream).getOrThrow().clone())
        }
        return this
    }
}

public class BytesResource <: DropletResource<Array<UInt8>> {
    public let bytes: Array<UInt8>

    public BytesResource(bytes: Array<UInt8>) {
        this.bytes = bytes
    }

    public override func getResourceTypeClass(): ResourceTypeClass {
        return ResourceTypeClass.RESOURCE_TYPE_ARRAY
    }

    public override func get(): Array<UInt8> {
        return bytes;
    }

    public override func getAsAny(): Any {
        return (bytes as Any).getOrThrow()
    }

    public override func getSize(): Int32 {
        return Int32(bytes.size);
    }

    public override func recycle(): Unit {
    }

    public func toString(): String {
        return "byteresource:${bytes}_${bytes.size}"
    }

    public func hashCode(): Int64 {
        Utils.hashCodeWrite<UInt8>(bytes, reset: true)
        return Utils.hashCodeFinish()
    }

    public operator func ==(that: AnyDropletResource): Bool {
        if (that is BytesResource) {
            let other = (that as BytesResource).getOrThrow()
            return other.bytes == bytes
        }
        return false
    }

    public operator func !=(that: AnyDropletResource): Bool {
        if (that is BytesResource) {
            let other = (that as BytesResource).getOrThrow()
            return other.bytes != bytes
        }
        return true
    }

    public func copy(): DropletResource<Array<UInt8>> {
        return this
    }
}
