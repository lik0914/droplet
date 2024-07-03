package glide

public class StringKey <: AnyKey {
    var str: String = ""

    public init(str: String) {
        this.str = str
    }

    public func toString():String {
        return "StringKey{str=${str}}";
    }

    public func equals(o: AnyKey): Bool {
        if (o is StringKey) {
            let other: StringKey = (o as StringKey).getOrThrow();
            return str == other.str;
        }
        return false;
    }

    public operator func ==(that: AnyKey): Bool {
        return equals(that)
    }

    public operator func !=(that: AnyKey): Bool {
        return !equals(that)
    }

    public func hashCode(): Int64 {
        return str.hashCode()
    }

    public func updateDiskCacheKey(md5: MD5): Unit {
        md5.MD5Update(str.toArray())
    }
}

