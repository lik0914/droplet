package glide

public interface CacheKeyUpdater<T> {
    /**
     * Updates the given {@link MessageDigest} with the bytes of the given key (to avoid incidental
     * value collisions when values are not particularly unique) and value.
     *
     * <p>If your {@link Option} shouldn't affect the disk cache key, you should not implement this
     * class and use {@link Option#memory(String)} or {@link Option#memory(String, Object)} instead.
     *
     * @param keyBytes The bytes of the {@link String} used as the key for this particular {@link
     *     Option}. Should be added to the {@code messageDigest} using {@link
     *     MessageDigest#update(byte[])} by all implementations if the digest is updated with the
     *     given {@code value} parameter.
     * @param value The value of of this particular option. Typically you should convert the value
     *     to a byte array using some stable mechanism and then call {@link
     *     MessageDigest#update(byte[])} to update the given digest.
     */
    // func update(keyBytes: Array<UInt8>, value: T): Unit
    func update(str: String, value: T, md5: MD5): Unit
}

public class EmptyUpdater<T> <: CacheKeyUpdater<T> {
    public func update(str: String, value: T, md5: MD5): Unit {}
}

public class GlideOptions <: AnyKey {
    public let values: CustomMap<AnyGlideOptionKey, AnyGlideOptionValue> = CachedHashCodeArrayMap<AnyGlideOptionKey, AnyGlideOptionValue>(
        );

    public func putAll(other: GlideOptions) {
        values.putAll((other.values as CustomMap<AnyGlideOptionKey, AnyGlideOptionValue>).getOrThrow());
    }

    public func set<V>(option: GlideOption<V>, value: V): GlideOptions where V <: AnyGlideOptionValue {
        values.put((option as AnyGlideOptionKey).getOrThrow(), (value as AnyGlideOptionValue).getOrThrow());
        return this;
    }

    public func get<V>(option: GlideOption<V>): V where V <: AnyGlideOptionValue {
        (values.get(option).getOrDefault({=> option.getDefaultValue().getOrThrow()}) as V).getOrThrow()
    }

    public func setOptions<V>(option: String, value: String): GlideOptions where V <: AnyGlideOptionValue {
        values.put((GlideOption<V>.memory(option) as AnyGlideOptionKey).getOrThrow(),
            (GlideString(value) as AnyGlideOptionValue).getOrThrow());
        return this;
    }

    public func getOptions(option: String): String {
        let o = GlideOption<GlideString>.memory(option);
        let r: GlideString = (values.get(o).getOrDefault({
            => o.getDefaultValue().getOrThrow()
        }) as GlideString).getOrThrow()
        return r.str
    }

    public func equals(o: AnyKey): Bool {
        if (o is GlideOptions) {
            var other: GlideOptions = (o as GlideOptions).getOrThrow();
            return values == other.values;
        }
        return false;
    }

    public override func hashCode(): Int64 {
        return values.hashCode();
    }

    public operator func ==(other: AnyKey) {
        return equals(other)
    }

    public operator func !=(other: AnyKey) {
        return !equals(other)
    }

    public func updateDiskCacheKey(md5: MD5): Unit {
        var i = 0
        while (i < values.size()) {
            var value: AnyGlideOptionValue = values.valueAt(i);
            var key: AnyGlideOptionKey = values.keyAt(i);
            // TODO 其他类型
            if (key is GlideOption<GlideInt>) {
                var option: GlideOption<GlideInt> = (key as GlideOption<GlideInt>).getOrThrow()
                updateDiskCacheKeyStatic<GlideInt>(option, value, md5);
            } else if (key is GlideOption<GlideString>) {
                var option: GlideOption<GlideString> = (key as GlideOption<GlideString>).getOrThrow()
                updateDiskCacheKeyStatic<GlideString>(option, value, md5);
            } else if (key is GlideOption<DownsampleStrategy>) {
                var option: GlideOption<DownsampleStrategy> = (key as GlideOption<DownsampleStrategy>).getOrThrow()
                updateDiskCacheKeyStatic<DownsampleStrategy>(option, value, md5);
            } else {
                throw GlideException("未知GlideOption类型")
            }

            i++
        }
    }

    private static func updateDiskCacheKeyStatic<T>(option: GlideOption<T>, value: AnyGlideOptionValue, md: MD5): Unit where T <: AnyGlideOptionValue {
        option.update((value as T).getOrThrow(), md);
    }

    public override func toString(): String {
        return "GlideOptions{values=${values}}"
    }
}
