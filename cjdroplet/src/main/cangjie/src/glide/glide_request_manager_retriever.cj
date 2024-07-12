/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2023-2024. All rights resvered.
 */
 
package glide

from ohos import ability.*

public class RequestManagerRetriever {

    private var factory: RequestManagerFactory;

    private var lifecycleRequestManagerRetriever: LifecycleRequestManagerRetriever;

    public init() {
        this.factory = DefaultRequestManagerFactory()
        lifecycleRequestManagerRetriever = LifecycleRequestManagerRetriever(this.factory);
    }

    public func get(context: AbilityContext, key: String) {
        var glide: Glide = Glide.get(context);
        return lifecycleRequestManagerRetriever.getOrCreate(
            context,
            glide,
            key,
            true);
    }

    public func getDeviceLifecycle(key: String): DeviceLifecycle {
        return lifecycleRequestManagerRetriever.getDeviceLifecycle(key)
    }
}

public class DefaultRequestManagerFactory <: RequestManagerFactory {
    public func build(glide: Glide, glideLifecycle: LifecycleLifecycle, context: AbilityContext, key: String): RequestManager {
        return RequestManager(glide, glideLifecycle, context, key)
    }
}

public interface RequestManagerFactory {
    func build(glide: Glide, glideLifecycle: LifecycleLifecycle, context: AbilityContext, key: String): RequestManager
}
