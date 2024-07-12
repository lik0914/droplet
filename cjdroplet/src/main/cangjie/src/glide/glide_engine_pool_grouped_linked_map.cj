/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2023-2024. All rights resvered.
 */
 
package glide

public class LinkedEntry<K, V> <: Equatable<LinkedEntry<K, V>> where K <: Equatable<K> & Hashable & ToString {
    public var key: Option<K> = None;
    private var values: ArrayList<V> = ArrayList<V>();
    public var next: Option<LinkedEntry<K, V>> = None;
    public var prev: Option<LinkedEntry<K, V>> = None;

    // Used only for the first item in the list which we will treat specially and which will not
    // contain a value.
    public init() {
      this(Option<K>.None);
    }

    public init(key: Option<K>) {
        this.key = key;

        this.next = Some(this)
        this.prev = Some(this)
      
    }

    public func removeLast(): Option<V> {
      let valueSize: Int64 = size();
      return if(valueSize > 0) {
        this.values.remove(valueSize - 1)
      } else {
        None
      };
    }

    public func size(): Int64 {
      return this.values.size
    }

    public func add(value: V): Unit {
      this.values.append(value);
    }

    public operator func ==(right: LinkedEntry<K, V>): Bool {
        return equals(right)
    }
    public operator func !=(right: LinkedEntry<K, V>): Bool {
      return !equals(right)
    } 

    public func equals(right: LinkedEntry<K, V>): Bool {
        if(match(this.key) {
            case Some(x) => true
            case _ => false
        } && match(right.key) {
                case Some(x) => true
                case _ => false
            }) {
            return this.key.getOrThrow() == right.key.getOrThrow()
        } else if(match(this.key) {
            case Some(x) => false
            case _ => true
        } && match(right.key) {
                case Some(x) => false
                case _ => true
            }) {
                return true
        } else {
            return false
        }
    }

    public func toString(): String {
        return if(match(this.key) {
            case Some(x) => true
            case _ => false
        }) {"None"} else {this.key.getOrThrow().toString()} 
    }
  }

public class GroupedLinkedMap<K, V> where K <: Poolable & Hashable & Equatable<K> & ToString {
  private let head: LinkedEntry<K, V> = LinkedEntry<K, V>();
  private let keyToEntry: HashMap<K, LinkedEntry<K, V>>  = HashMap<K, LinkedEntry<K, V>>();

  public func put(key: K, value: V): Unit {
    var entry: Option<LinkedEntry<K, V>> = keyToEntry.get(key);

    if(match(entry) {
        case Some(x) => false
        case _ => true
    }) {
      entry = Some(LinkedEntry<K, V>(Some(key)));
      makeTail(entry.getOrThrow());
      let b = keyToEntry.put(key, entry.getOrThrow());
    } else {
      key.offer();
    }

    entry.getOrThrow().add(value);
  }

  public func get(key: K): Option<V> {
    var entry: Option<LinkedEntry<K, V>> = keyToEntry.get(key);
    if (match(entry) {
        case Some(x) => false
        case _ => true
    }) {
      entry = Some(LinkedEntry<K, V>(Some(key)))
      let b = keyToEntry.put(key, entry.getOrThrow());
    } else {
      key.offer();
    }

    let en = entry.getOrThrow()

    makeHead(en);

    return en.removeLast();
  }

  public func removeLast(): Option<V> {
    var last: LinkedEntry<K, V> = head.prev.getOrThrow();

    while (!last.equals(head)) {
      let removed: Option<V> = last.removeLast();
      if (match(removed) {
        case Some(x) => true
        case _ => false
      }) {
        return removed;
      } else {
        // We will clean up empty lru entries since they are likely to have been one off or
        // unusual sizes and
        // are not likely to be requested again so the gc thrash should be minimal. Doing so will
        // speed up our
        // removeLast operation in the future and prevent our linked list from growing to
        // arbitrarily large
        // sizes.
        removeEntry(last);
        keyToEntry.remove(last.key.getOrThrow());
        last.key.getOrThrow().offer();
      }

      last = last.prev.getOrThrow();
    }

    return None;
  }

  public func toString(): String {
    var sb: StringBuilder = StringBuilder("GroupedLinkedMap( ");
    var current: LinkedEntry<K, V> = head.next.getOrThrow();
    var hadAtLeastOneItem: Bool  = false;
    while (!current.equals(head)) {
      hadAtLeastOneItem = true;
      //适配
      //sb.append('{').append(current.key.getOrThrow()).append(':').append(current.size()).append("}, ");
      sb.append('{')
      sb.append(current.key.getOrThrow())
      sb.append(':')
      sb.append(current.size())
      sb.append("}, ")
      current = current.next.getOrThrow();
    }
    if (hadAtLeastOneItem) {
        let r = Range<Int64>(sb.size - 2, sb.size, 1, true, false, true)
        //适配
        //sb.remove(r);
        var strTemp = sb.toString()
        let r2: Range<Int64> = 0 .. sb.size - 2
        var subStrTemp = strTemp[r2]
        sb = StringBuilder(subStrTemp)
    }
    return sb.append(" )").toString();
  }

  // Make the entry the most recently used item.
  private func makeHead(entry: LinkedEntry<K, V>): Unit {
    removeEntry<K, V>(entry);
    entry.prev = head;
    entry.next = head.next;
    updateEntry<K, V>(entry);
  }

  // Make the entry the least recently used item.
  private func makeTail(entry: LinkedEntry<K, V>): Unit {
    removeEntry<K, V>(entry);
    entry.prev = head.prev;
    entry.next = head;
    updateEntry<K, V>(entry);
  }

  private static func updateEntry<K, V>(entry: LinkedEntry<K, V>) where K <: Poolable & Hashable & Equatable<K> & ToString {
    entry.next.getOrThrow().prev = Some(entry);
    entry.prev.getOrThrow().next = Some(entry);
  }

  private static func removeEntry<K, V>(entry: LinkedEntry<K, V>) where K <: Poolable & Hashable & Equatable<K> & ToString  {
    entry.prev.getOrThrow().next = entry.next;
    entry.next.getOrThrow().prev = entry.prev;
  }
  
}
