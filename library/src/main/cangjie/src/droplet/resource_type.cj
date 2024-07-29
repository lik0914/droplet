/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2023-2024. All rights resvered.
 */
 
package droplet.droplet

public class ResourceTypeClass <: DropletAny<ResourceTypeClass> {

    private static let NONE: Int64 = 0
    private static let ARRAY: Int64 = 101
    private static let PIXELMAP: Int64 = 102
    private static let INPUTSTREAM: Int64 = 103
    private static let GIFDRAWABLE: Int64 = 104

    public static let RESOURCE_TYPE_NONE: ResourceTypeClass = ResourceTypeClass(NONE)
    public static let RESOURCE_TYPE_ARRAY: ResourceTypeClass = ResourceTypeClass(ARRAY)
    public static let RESOURCE_TYPE_PIXELMAP: ResourceTypeClass = ResourceTypeClass(PIXELMAP)
    public static let RESOURCE_TYPE_INPUTSTREAM: ResourceTypeClass = ResourceTypeClass(INPUTSTREAM)
    public static let RESOURCE_TYPE_GIFDRAWABLE: ResourceTypeClass = ResourceTypeClass(GIFDRAWABLE)
    
    // 1 ARRAY  2 PIXELMAP
    public var resourceType: Int64 = NONE

    public init(resourceType: Int64) {
        this.resourceType = resourceType
    }

    public func toString(): String {
        return "ResourceTypeClass ${resourceType}"
    }

    public func hashCode(): Int64 {
        return this.resourceType.hashCode()
    }

    public operator func ==(that: ResourceTypeClass): Bool {
        if(that is ResourceTypeClass) {
            return this.resourceType == that.resourceType
        }
        return false
    }

    public operator func !=(that: ResourceTypeClass): Bool {
        if(that is ResourceTypeClass) {
            return this.resourceType != that.resourceType
        }
        return true
    }
}
