/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2023-2024. All rights resvered.
 */
 
package droplet.droplet

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

public class DropletOptions <: AnyKey {
    public let values: CustomMap<AnyDropletOptionKey, AnyDropletOptionValue> = CachedHashCodeArrayMap<AnyDropletOptionKey, AnyDropletOptionValue>(
        );

    public func putAll(other: DropletOptions) {
        values.putAll((other.values as CustomMap<AnyDropletOptionKey, AnyDropletOptionValue>).getOrThrow());
    }

    public func set<V>(option: DropletOption<V>, value: V): DropletOptions where V <: AnyDropletOptionValue {
        values.put((option as AnyDropletOptionKey).getOrThrow(), (value as AnyDropletOptionValue).getOrThrow());
        return this;
    }

    public func get<V>(option: DropletOption<V>): V where V <: AnyDropletOptionValue {
        (values.get(option).getOrDefault({=> option.getDefaultValue().getOrThrow()}) as V).getOrThrow()
    }

    public func setOptions<V>(option: String, value: String): DropletOptions where V <: AnyDropletOptionValue {
        values.put((DropletOption<V>.memory(option) as AnyDropletOptionKey).getOrThrow(),
            (DropletString(value) as AnyDropletOptionValue).getOrThrow());
        return this;
    }

    public func getOptions(option: String): String {
        let o = DropletOption<DropletString>.memory(option);
        let r: DropletString = (values.get(o).getOrDefault({
            => o.getDefaultValue().getOrThrow()
        }) as DropletString).getOrThrow()
        return r.str
    }

    public func equals(o: AnyKey): Bool {
        if (o is DropletOptions) {
            var other: DropletOptions = (o as DropletOptions).getOrThrow();
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
            var value: AnyDropletOptionValue = values.valueAt(i);
            var key: AnyDropletOptionKey = values.keyAt(i);
            // TODO 其他类型
            if (key is DropletOption<DropletInt>) {
                var option: DropletOption<DropletInt> = (key as DropletOption<DropletInt>).getOrThrow()
                updateDiskCacheKeyStatic<DropletInt>(option, value, md5);
            } else if (key is DropletOption<DropletString>) {
                var option: DropletOption<DropletString> = (key as DropletOption<DropletString>).getOrThrow()
                updateDiskCacheKeyStatic<DropletString>(option, value, md5);
            } else if (key is DropletOption<DownsampleStrategy>) {
                var option: DropletOption<DownsampleStrategy> = (key as DropletOption<DownsampleStrategy>).getOrThrow()
                updateDiskCacheKeyStatic<DownsampleStrategy>(option, value, md5);
            } else {
                throw DropletException("未知DropletOption类型")
            }

            i++
        }
    }

    private static func updateDiskCacheKeyStatic<T>(option: DropletOption<T>, value: AnyDropletOptionValue, md: MD5): Unit where T <: AnyDropletOptionValue {
        option.update((value as T).getOrThrow(), md);
    }

    public override func toString(): String {
        return "DropletOptions{values=${values}}"
    }
}
