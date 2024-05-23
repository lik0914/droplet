package glide

from std import collection.*

from ohos import base.*


public interface LifecycleListener <: Hashable & Equatable<LifecycleListener> {

  func onStart(): Unit;

  func onStop(): Unit;

  func onDestroy(): Unit;
}

public interface Lifecycle {
  func addListener(listener: LifecycleListener): Unit;

  func removeListener(listener: LifecycleListener): Unit;
}

public interface LifecycleObserver <: Hashable & Equatable<LifecycleObserver> {
  func onStart(): Unit

  func onStop(): Unit

  func onDestroy(): Unit
}

public class DeviceLifecycle <: Hashable & Equatable<DeviceLifecycle> {
  public let key: String
  private let state: LifecycleState = LifecycleState()
  private var observer: HashSet<LifecycleObserver> = HashSet<LifecycleObserver>()

  public init(key: String) {
    this.key = key
  }
  
  public func getCurrentState(): Int64 {
    return this.state.getCurrentState()
  }

  public func isAtLeast(s: Int64): Bool {
    return this.state.isAtLeast(s)
  }

  public func setCurrentState(s: Int64): Unit {
    this.state.setCurrentState(s)
  }

  public func addObserver(o: LifecycleObserver): Unit {
    AppLog.error("DeviceLifecycle addObserver ${this.observer.size}")
    this.observer.put(o)
  }

  public func removeObserver(o: LifecycleObserver): Unit {
    AppLog.error("DeviceLifecycle removeObserver ${this.observer.size}")
    this.observer.remove(o)
  }

  public func onAppear(): Unit {
    AppLog.error("DeviceLifecycle onAppear ${this.observer.size}")
    setCurrentState(LifecycleState.STATE_STARTED)
    for(o in this.observer) {
      o.onStart()
    }
  }

  public func onDisAppear(): Unit {
    AppLog.error("DeviceLifecycle onDisAppear ${this.observer.size}")
    setCurrentState(LifecycleState.STATE_DESTROYED)
    for(o in this.observer) {
      o.onStop()
      o.onDestroy()
    }
  }
  
  public operator func ==(right: DeviceLifecycle): Bool {
    return key == right.key
  }
  public operator func !=(right: DeviceLifecycle): Bool {
    return key != right.key
  } 
  public func hashCode(): Int64 {
    return key.hashCode()
  }

}

public class LifecycleState {
  public static var STATE_DESTROYED: Int64 = 0xF1;
  public static var STATE_INITIALIZED: Int64 = 0xF2;
  public static var STATE_CREATED: Int64 = 0xF3;
  public static var STATE_STARTED: Int64 = 0xF4;
  public static var STATE_RESUMED: Int64 = 0xF5;

  public var state: Int64;

  public init() {
    this.state = STATE_INITIALIZED
  }

  public init(s: Int64) {
    this.state = s
  }

  public func getCurrentState(): Int64 {
    return this.state
  }

  public func isAtLeast(s: Int64): Bool {
    return (this.state - s) >= 0;
  }

  public func setCurrentState(s: Int64): Unit {
    this.state = s
  }

}

public class LifecycleLifecycle <: Lifecycle & LifecycleObserver {
  public var deviceLifecycle: DeviceLifecycle;
  private var lifecycleListeners: HashSet<LifecycleListener> = HashSet<LifecycleListener>();

  public init(deviceLifecycle: DeviceLifecycle) {
    this.deviceLifecycle = deviceLifecycle
    deviceLifecycle.addObserver(this)
  }

  public override func addListener(listener: LifecycleListener): Unit {
    AppLog.error("LifecycleLifecycle addListener begin")
    lifecycleListeners.put(listener);

    if (deviceLifecycle.getCurrentState() == LifecycleState.STATE_DESTROYED) {
      AppLog.error("LifecycleLifecycle addListener: state.getCurrentState() == LifecycleState.STATE_DESTROYED")
      listener.onDestroy();
    } else if (deviceLifecycle.isAtLeast(LifecycleState.STATE_STARTED)) {
      AppLog.error("LifecycleLifecycle addListener: state.isAtLeast(LifecycleState.STATE_STARTED)")
      listener.onStart();
    } else {
      AppLog.error("LifecycleLifecycle addListener: state other")
      listener.onStop();
    }
  }

  public override func removeListener(listener: LifecycleListener): Unit {
    lifecycleListeners.remove(listener);
  }

  public func onStart(): Unit {
    for (lifecycleListener in Utils.getSnapshot(lifecycleListeners)) {
      lifecycleListener.onStart();
    }
  }

  public func onStop(): Unit {
    for (lifecycleListener in Utils.getSnapshot(lifecycleListeners)) {
      lifecycleListener.onStop();
    }
  }

  public func onDestroy(): Unit {
    
    for (lifecycleListener in Utils.getSnapshot(lifecycleListeners)) {
      lifecycleListener.onDestroy();
    }

    // removeObserver
  }

  public operator func ==(right: LifecycleObserver): Bool {
    if(right is LifecycleLifecycle) {
      return deviceLifecycle == (right as LifecycleLifecycle).getOrThrow().deviceLifecycle
    } else {
      return false
    }
  }
  public operator func !=(right: LifecycleObserver): Bool {
    if(right is LifecycleLifecycle) {
      return deviceLifecycle != (right as LifecycleLifecycle).getOrThrow().deviceLifecycle
    } else {
      return true
    }
  } 
  public func hashCode(): Int64 {
    deviceLifecycle.hashCode()
  }
}