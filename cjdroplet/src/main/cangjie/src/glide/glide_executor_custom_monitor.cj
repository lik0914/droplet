package glide

public class CustomMonitor {
    public let monitor: Monitor
    public var waitFlag: Bool = true
    public init(m: Monitor) {
        this.monitor = m
    }

    public init(m: Monitor, flag: Bool) {
        this.monitor = m
        this.waitFlag = flag
    }

}
