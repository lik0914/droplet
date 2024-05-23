package glide


public interface AnyKey <: GlideAny<AnyKey> {
    /**
    * Adds all uniquely identifying information to the given digest.
    *
    * <p>Note - Using {@link java.security.MessageDigest#reset()} inside of this method will result
    * in undefined behavior.
    */
    func updateDiskCacheKey(md5: MD5): Unit;
}

public open class AnyGlideOptionKey <: Hashable & ToString & Equatable<AnyGlideOptionKey> {
    protected let key: String

    public init(key: String) {
        this.key = key
    }

    public open operator func ==(that: AnyGlideOptionKey): Bool {
        //适配
        //return key.equals(that.key);
        return key == that.key
    }

    public open operator func !=(that: AnyGlideOptionKey): Bool {
        //适配
        //return !key.equals(that.key);
        return key != that.key
    }

    public open func hashCode(): Int64 {
        return key.hashCode()
    }

    public open func toString(): String {
        return "Option{key=${key}}";
    }

}
