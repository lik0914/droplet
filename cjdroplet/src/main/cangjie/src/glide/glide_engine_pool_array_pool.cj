package glide

from std import collection.*
from std import sync.*

public interface ArrayPool {

    func put(array: Array<UInt8>): Unit;

    func get(size: Int64): Array<UInt8> 

  func getExact(size: Int64): Array<UInt8>

  /** Clears all arrays from the pool. */
  func clearMemory(): Unit;

  func trimMemory(level: Int64): Unit;
}

public interface ArrayAdapterInterface<T> {

  /** TAG for logging. */
  func getTag(): String;

  /** Return the length of the given array. */
  func getArrayLength(array: T): Int64;

  /** Allocate and return an array of the specified size. */
  func newArray(length: Int64): T;

  /** Return the size of an element in the array in bytes (e.g. for int return 4). */
  func getElementSizeInBytes(): Int64;
}

public class UInt8ArrayAdapter <: ArrayAdapterInterface<Array<UInt8>> {
   public func getTag(): String {
    return "ByteArrayPool"
    }

  /** Return the length of the given array. */
  public func getArrayLength(array: Array<UInt8>): Int64 {
    return array.size
  }

  /** Allocate and return an array of the specified size. */
  public func newArray(length: Int64): Array<UInt8> {
    return Array<UInt8>(length, item: 0)
  }

  /** Return the size of an element in the array in bytes (e.g. for int return 4). */
  public func getElementSizeInBytes(): Int64 {
    return 1
  }
  
}

public class Key <: Poolable & Equatable<Key> & Hashable & ToString {
    private let pool: KeyPool;
    public var size: Int64 = 0;
    public var arrType: Int64 = 0

    public init(pool: KeyPool) {
      this.pool = pool;
    }

    public operator func ==(right: Key): Bool {
      this.equals(right)
    }
    public operator func !=(right: Key): Bool {
      !this.equals(right)
    } 

    public func initKey(length: Int64, arrType: Int64): Unit {
      this.size = length;
      this.arrType = arrType
    }

    public func equals(o: Any): Bool {
      if (o is Key) {
        let other: Key = (o as Key).getOrThrow();
        return size == other.size && arrType == other.arrType;
      }
      return false;
    }

    public func toString(): String {
      return "Key{size=${size}, arrType=${arrType}}";
    }

    public func offer(): Unit {
      pool.offer(this);
    }

    public func hashCode(): Int64 {
      Utils.hashCodeWrite(size, reset: true)
      Utils.hashCodeWrite(arrType, reset: false)
      return Utils.hashCodeFinish();
    }

  }

public class KeyPool <: BaseKeyPool<Key> {

    public func get(size: Int64, arrType: Int64): Key {
      let result: Key = get();
      result.initKey(size, arrType);
      return result;
    }

    public override func create(): Key {
      return Key(this);
    }
}

public class LruArrayPool <: ArrayPool {
    public static let STANDARD_BUFFER_SIZE_BYTES: Int64 = 64 * 1024;

    public static let DEFAULT_SIZE: Int64 = 4 * 1024 * 1024;
    public static let MAX_OVER_SIZE_MULTIPLE: Int64 = 8;
    public static let SINGLE_ARRAY_MAX_SIZE_DIVISOR: Int64 = 2;

    public static let ARR_TYPE_U8: Int64 = 1

    private let uint8GroupedMap: GroupedLinkedMap<Key, Array<UInt8>> = GroupedLinkedMap<Key, Array<UInt8>>();
    private let keyPool: KeyPool = KeyPool();
    private let sortedSizes: HashMap<Int64, HashMap<Int64, Int64>> = HashMap<Int64, HashMap<Int64, Int64>>();
    private let uint8Adapter: UInt8ArrayAdapter = UInt8ArrayAdapter();
    private let maxSize: Int64;
    private var currentSize: Int64 = 0;
    private let mtx = ReentrantMutex()

    public init() {
        this.maxSize = DEFAULT_SIZE;
    }

    public init(maxSize: Int64) {
        this.maxSize = maxSize;
    }

    public func put(array: Array<UInt8>): Unit {
        synchronized(mtx) {
            let size: Int64 = uint8Adapter.getArrayLength(array);
            let arrayBytes: Int64 = size * uint8Adapter.getElementSizeInBytes();
            if (!isSmallEnoughForReuse(arrayBytes)) {
                return;
            }
            let key: Key = keyPool.get(size, ARR_TYPE_U8);

            uint8GroupedMap.put(key, array);

            var sizes: HashMap<Int64, Int64> = getSizesForAdapter(ARR_TYPE_U8);
            
            let current: Option<Int64> = sizes.get(key.size);
            var keySize: Int64 = 1
            if(match(current) {
                case Some(x) => true
                case _ => false
            }) {
                keySize = current.getOrThrow() + 1
            }

            sizes.put(key.size, keySize);
            currentSize += arrayBytes;
            evictUInt8Arr();
        }
    }

    private func evictUInt8Arr(): Unit {
        evictToSizeUInt8Arr(maxSize);
    }

    private func evictToSizeUInt8Arr(size: Int64): Unit {
        while (currentSize > size) {
            var evicted: Option<Array<UInt8>> = uint8GroupedMap.removeLast();
            // Preconditions.checkNotNull(evicted);
            if(match(evicted) {
                case Some(x) => false
                case _ => true
            }) {
                throw GlideException("evictToSizeUInt8Arr error")
            }

            let ev = evicted.getOrThrow()
            
            currentSize -= uint8Adapter.getArrayLength(ev) * uint8Adapter.getElementSizeInBytes();
            decrementArrayOfSize(uint8Adapter.getArrayLength(ev), ARR_TYPE_U8);
            // if (Log.isLoggable(uint8Adapter.getTag(), Log.VERBOSE)) {
            //     Log.v(uint8Adapter.getTag(), "evicted: " + uint8Adapter.getArrayLength(evicted));
            // }
        }
    }

    private func decrementArrayOfSize(size: Int64, arrType: Int64): Unit {
        let sizes: HashMap<Int64, Int64> = getSizesForAdapter(arrType);
        let current: Option<Int64> = sizes.get(size);
        if (match(current) {
            case Some(x) => false
            case _ => true
        }) {
            throw GlideException("Tried to decrement empty size, size: ${size}");
        }
        let c = current.getOrThrow()
        if (c == 1) {
            sizes.remove(size);
        } else {
            sizes.put(size, c - 1);
        }
    }

    private func getSizesForAdapter(arrType: Int64): HashMap<Int64, Int64> {
        var sizes: Option<HashMap<Int64, Int64>> = sortedSizes.get(arrType);
        if (match(sizes) {
            case Some(x) => false
            case _ => true
        }) {
            // TODO TreeMap
            let s = HashMap<Int64, Int64>()
            sizes = Some(s);
            sortedSizes.put(arrType, s);
        }
        return sizes.getOrThrow();
    }

    private func isSmallEnoughForReuse(byteSize: Int64): Bool {
        return byteSize <= maxSize / SINGLE_ARRAY_MAX_SIZE_DIVISOR;
    }

    public func get(size: Int64): Array<UInt8> {
        synchronized(mtx) {
            // let possibleSize: Int64 = getSizesForAdapter(arrType).ceilingKey(size);
            //适配
            //let keys: Keys<Int64> = getSizesForAdapter(ARR_TYPE_U8).keys();
            let keys = getSizesForAdapter(ARR_TYPE_U8).keys()
            var possibleSize: Option<Int64> = None

            var com: Int64 = 0
            var minCom: Int64 = 0x7FFFFFFFFFFFFFFF
            for(k in keys) {
                com = k - size
                if(com >= 0 && com < minCom) {
                    minCom = com
                    possibleSize = Some(k)
                }
            }

            let key: Key;
            if (mayFillRequest(size, possibleSize)) {
                key = keyPool.get(possibleSize.getOrThrow(), ARR_TYPE_U8);
            } else {
                key = keyPool.get(size, ARR_TYPE_U8);
            }
            return getForKey(key, ARR_TYPE_U8);
        }
    }

    public func getExact(size: Int64): Array<UInt8> {
        synchronized(mtx) {
            let key: Key = keyPool.get(size, ARR_TYPE_U8);
            return getForKey(key, ARR_TYPE_U8);
        }
    }

    private func getForKey(key: Key, arrType: Int64): Array<UInt8> {
        // var arrayAdapter: ArrayAdapterInterface<T> = getAdapterFromType(ARR_TYPE_U8);
        let result: Option<Array<UInt8>> = getArrayForKey(key);
        if (match(result) {
            case Some(x) => true
            case _ => false
        }) {
            let r = result.getOrThrow()
            currentSize -= uint8Adapter.getArrayLength(r) * uint8Adapter.getElementSizeInBytes();
            decrementArrayOfSize(uint8Adapter.getArrayLength(r), arrType);
            return r
        } else {
            // if (Log.isLoggable(uint8Adapter.getTag(), Log.VERBOSE)) {
            //     Log.v(uint8Adapter.getTag(), "Allocated " + key.size + " bytes");
            // }
            return uint8Adapter.newArray(key.size);
        }
        // return result;
    }

    private func getArrayForKey(key: Key): Option<Array<UInt8>> {
        return uint8GroupedMap.get(key);
    }

    private func mayFillRequest(requestedSize: Int64, actualSize: Option<Int64>): Bool {
        return match(actualSize) {
            case Some(x) => true
            case _ => false
        } && (isNoMoreThanHalfFull() || actualSize.getOrThrow() <= (MAX_OVER_SIZE_MULTIPLE * requestedSize))


        // return actualSize != null
        //     && (isNoMoreThanHalfFull() || actualSize <= (MAX_OVER_SIZE_MULTIPLE * requestedSize));
    }

    private func isNoMoreThanHalfFull(): Bool {
        return currentSize == 0 || (maxSize / currentSize >= 2);
    }

    /** Clears all arrays from the pool. */
    public func clearMemory(): Unit {
        synchronized(mtx) {
            evictToSize(0);
        }
    }

    public func getMaxSize(): Int64 {
        return maxSize
    }

    public func trimMemory(level: Int64): Unit {
        synchronized(mtx) {
            // Name	                Value	Description
            // MEMORY_LEVEL_MODERATE	0	  Moderate memory usage.
            // MEMORY_LEVEL_LOW	      1	  Low memory usage.
            // MEMORY_LEVEL_CRITICAL	2	  High memory usage.
            if (level == 2) {
                // 全部清空
                clearMemory();
            } else if (level == 0) {
                // 清空一半内存
                evictToSize(getMaxSize() / 2);
            }
        }
        
    }

    private func evictToSize(size: Int64): Unit {
        while (currentSize > size) {
            let evicted: Option<Array<UInt8>> = uint8GroupedMap.removeLast();
            // Preconditions.checkNotNull(evicted);
            if(match(evicted) {
                case Some(x) => false
                case _ => true
            }) {
                throw GlideException("evicted error")
            }

            // ArrayAdapterInterface<Object> arrayAdapter = getAdapterFromObject(evicted);
            let arrayLength = uint8Adapter.getArrayLength(evicted.getOrThrow())
            let elementSizeBytes = uint8Adapter.getElementSizeInBytes();

            let targetLength = arrayLength * elementSizeBytes;
            currentSize = currentSize - targetLength
            decrementArrayOfSize(uint8Adapter.getArrayLength(evicted.getOrThrow()), ARR_TYPE_U8);
            // if (Log.isLoggable(arrayAdapter.getTag(), Log.VERBOSE)) {
            //     Log.v(arrayAdapter.getTag(), "evicted: " + arrayAdapter.getArrayLength(evicted));
            // }
        }
    }

    public func getCurrentSize(): Int64 {
        var cSize: Int64 = 0;
        var sizes: HashMap<Int64, Int64> = getSizesForAdapter(ARR_TYPE_U8);

        for (size in sizes.keys()) {
            cSize += size * sizes.get(size).getOrThrow() * uint8Adapter.getElementSizeInBytes();
        }
        return cSize;
    }

}
