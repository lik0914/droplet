/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2023-2024. All rights resvered.
 */
 
package droplet.droplet

public class TransformationKey <: DropletAny<TransformationKey> {

    public static let TRANSFORMATION_NONE: Int64 = 0
    public static let TRANSFORMATION_DRAWABLE: Int64 = 201
    public static let TRANSFORMATION_PIXELMAP: Int64 = 202
    public static let TRANSFORMATION_INPUTSTREAM: Int64 = 203
    
    // 1 ARRAY  2 PIXELMAP
    public var tType: Int64 = TRANSFORMATION_NONE

    public init(tType: Int64) {
        this.tType = tType
    }

    public func toString(): String {
        if(tType == TRANSFORMATION_NONE) {
            return "TransformationKey : TRANSFORMATION_NONE"
        } else if(tType == TRANSFORMATION_PIXELMAP) {
            return "TransformationKey : TRANSFORMATION_PIXELMAP"
        } else if(tType == TRANSFORMATION_INPUTSTREAM) {
            return "TransformationKey : TRANSFORMATION_INPUTSTREAM"
        } else if(tType == TRANSFORMATION_DRAWABLE) {
            return "TransformationKey : TRANSFORMATION_DRAWABLE"
        } else {
            throw DropletException("unknow TransformationKey")
        }
    }

    public func hashCode(): Int64 {
        return this.tType.hashCode()
    }

    public operator func ==(that: TransformationKey): Bool {
        return this.tType == that.tType
    }

    public operator func !=(that: TransformationKey): Bool {
        return this.tType != that.tType
    }
}
