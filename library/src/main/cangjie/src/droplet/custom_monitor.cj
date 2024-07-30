/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2023-2024. All rights resvered.
 */
 
package droplet.droplet

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
