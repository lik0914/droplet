/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2023-2024. All rights resvered.
 */
 
package droplet.droplet


public class RequestManagerRetriever {

    private var factory: RequestManagerFactory;

    private var lifecycleRequestManagerRetriever: LifecycleRequestManagerRetriever;

    public init() {
        this.factory = DefaultRequestManagerFactory()
        lifecycleRequestManagerRetriever = LifecycleRequestManagerRetriever(this.factory);
    }

    public func get(context: AbilityContext, key: String) {
        var droplet: Droplet = Droplet.get(context);
        return lifecycleRequestManagerRetriever.getOrCreate(
            context,
            droplet,
            key,
            true);
    }

    public func getDeviceLifecycle(key: String): DeviceLifecycle {
        return lifecycleRequestManagerRetriever.getDeviceLifecycle(key)
    }
}

public class DefaultRequestManagerFactory <: RequestManagerFactory {
    public func build(droplet: Droplet, dropletLifecycle: LifecycleLifecycle, context: AbilityContext, key: String): RequestManager {
        return RequestManager(droplet, dropletLifecycle, context, key)
    }
}

public interface RequestManagerFactory {
    func build(droplet: Droplet, dropletLifecycle: LifecycleLifecycle, context: AbilityContext, key: String): RequestManager
}
