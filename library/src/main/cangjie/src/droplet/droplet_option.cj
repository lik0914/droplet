/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2023-2024. All rights resvered.
 */
 
package droplet.droplet

public class DropletOption<T> <: AnyDropletOptionKey & Equatable<DropletOption<T>> where T <: AnyDropletOptionValue {
    private static let EMPTY_UPDATER: EmptyUpdater<T> = EmptyUpdater<T>()
    private let defaultValue: Option<T>
    private let cacheKeyUpdater: CacheKeyUpdater<T>
    private var keyBytes: Array<UInt8>

    private init(key: String, defaultValue: T, cacheKeyUpdater: CacheKeyUpdater<T>) {
        super(key)
        this.defaultValue = Some(defaultValue)
        this.cacheKeyUpdater = cacheKeyUpdater
        this.keyBytes = key.toArray()
    }

    private init(key: String, cacheKeyUpdater: CacheKeyUpdater<T>) {
        super(key)
        this.defaultValue = None
        this.cacheKeyUpdater = cacheKeyUpdater
        this.keyBytes = key.toArray()
    }

    private func getKeyBytes(): Array<UInt8> {
        return keyBytes;
    }

    public func equals<V>(o: Any): Bool where V <: AnyDropletOptionValue {
        if (o is DropletOption<V>) {
            var other: DropletOption<V> = (o as DropletOption<V>).getOrThrow();
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

    public static func disk<V>(key: String, defaultValue: V, cacheKeyUpdater: CacheKeyUpdater<V>): DropletOption<V> where V <: AnyDropletOptionValue {
        return DropletOption<V>(key, defaultValue, cacheKeyUpdater);
    }

    public static func disk<V>(key: String, cacheKeyUpdater: CacheKeyUpdater<V>): DropletOption<V> where V <: AnyDropletOptionValue {
        return DropletOption<V>(key, cacheKeyUpdater);
    }

    public static func memory(key: String, defaultValue: T): DropletOption<T> {
        return DropletOption<T>(key, defaultValue, emptyUpdater());
    }

    public static func memory(key: String): DropletOption<T> {
        return DropletOption<T>(key, emptyUpdater());
    }

    public operator func ==(that: DropletOption<T>): Bool {
        return key == that.key
    }

    public operator func !=(that: DropletOption<T>): Bool {
        return key != that.key
    }
}
