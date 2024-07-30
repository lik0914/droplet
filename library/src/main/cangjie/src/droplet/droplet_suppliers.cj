/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2023-2024. All rights resvered.
 */
 
package droplet.droplet


public interface DropletSupplier<T> {
    func get(): Option<T>
}

public class DefaultDropletSupplier<T> <: DropletSupplier<T> {
    private var instance: Option<T> = Option<T>.None;
    private let mtx = ReentrantMutex();

    public DefaultDropletSupplier(let supplier: DropletSupplier<T>) {

    }

    public func get(): Option<T> {
        if (match(instance) {
            case Some(x) => false
            case _ => true
        }) {
            synchronized (mtx) {
                if (match(instance) {
                    case Some(x) => false
                    case _ => true
                }) {
                    instance = supplier.get();
                }
            }
        }
        return instance;
    }
}

public class DropletSuppliers {
    private DropletSuppliers() {}

    public static func memorize<T>(supplier: DropletSupplier<T>): DropletSupplier<T> {
        return DefaultDropletSupplier<T>(supplier);
    }
}


