/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2023-2024. All rights resvered.
 */
 
package droplet.droplet

public interface AnyKey <: DropletAny<AnyKey> {
    /**
    * Adds all uniquely identifying information to the given digest.
    *
    * <p>Note - Using {@link java.security.MessageDigest#reset()} inside of this method will result
    * in undefined behavior.
    */
    func updateDiskCacheKey(md5: MD5): Unit;
}

public open class AnyDropletOptionKey <: Hashable & ToString & Equatable<AnyDropletOptionKey> {
    protected let key: String

    public init(key: String) {
        this.key = key
    }

    public open operator func ==(that: AnyDropletOptionKey): Bool {
        return key == that.key
    }

    public open operator func !=(that: AnyDropletOptionKey): Bool {
        return key != that.key
    }

    public open func hashCode(): Int64 {
        return key.hashCode()
    }

    public open func toString(): String {
        return "Option{key=${key}}";
    }

}
