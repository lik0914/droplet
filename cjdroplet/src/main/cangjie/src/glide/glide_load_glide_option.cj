/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2023-2024. All rights resvered.
 */
 
package glide

public class GlideOption<T> <: AnyGlideOptionKey & Equatable<GlideOption<T>> where T <: AnyGlideOptionValue {
    private static let EMPTY_UPDATER: EmptyUpdater<T> = EmptyUpdater<T>()
    private let defaultValue: Option<T>
    private let cacheKeyUpdater: CacheKeyUpdater<T>
    private var keyBytes: Array<UInt8>

    private init(key: String, defaultValue: T, cacheKeyUpdater: CacheKeyUpdater<T>) {
        super(key)
        this.defaultValue = Some(defaultValue)
        this.cacheKeyUpdater = cacheKeyUpdater
        //适配
        //this.keyBytes = key.toUtf8Array()
        this.keyBytes = key.toArray()
    }

    private init(key: String, cacheKeyUpdater: CacheKeyUpdater<T>) {
        super(key)
        this.defaultValue = None
        this.cacheKeyUpdater = cacheKeyUpdater
        //适配
        //this.keyBytes = key.toUtf8Array()
        this.keyBytes = key.toArray()
    }

    private func getKeyBytes(): Array<UInt8> {
        return keyBytes;
    }

    public func equals<V>(o: Any): Bool where V <: AnyGlideOptionValue {
        if (o is GlideOption<V>) {
            var other: GlideOption<V> = (o as GlideOption<V>).getOrThrow();
            //适配
            //return key.equals(other.key);
            return key == other.key
        }
        return false;
    }

    private static func emptyUpdater(): CacheKeyUpdater<T> {
        return EMPTY_UPDATER
    }

    public func update(value: T, md5: MD5) {
        cacheKeyUpdater.update(key, value, md5);
    }

    public func getDefaultValue(): Option<T> {
        return defaultValue;
    }

    public static func disk<V>(key: String, defaultValue: V, cacheKeyUpdater: CacheKeyUpdater<V>): GlideOption<V> where V <: AnyGlideOptionValue {
        return GlideOption<V>(key, defaultValue, cacheKeyUpdater);
    }

    public static func disk<V>(key: String, cacheKeyUpdater: CacheKeyUpdater<V>): GlideOption<V> where V <: AnyGlideOptionValue {
        return GlideOption<V>(key, cacheKeyUpdater);
    }

    public static func memory(key: String, defaultValue: T): GlideOption<T> {
        return GlideOption<T>(key, defaultValue, emptyUpdater());
    }

    public static func memory(key: String): GlideOption<T> {
        return GlideOption<T>(key, emptyUpdater());
    }

    public operator func ==(that: GlideOption<T>): Bool {
        //适配
        //return key.equals(that.key);
        return key == that.key
    }

    public operator func !=(that: GlideOption<T>): Bool {
        //适配
        //return !key.equals(that.key);
        return key != that.key
    }
}
