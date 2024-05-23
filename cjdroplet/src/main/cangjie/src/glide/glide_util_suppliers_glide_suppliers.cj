package glide

from std import sync.*

public interface GlideSupplier<T> {
    func get(): Option<T>
}

public class DefaultGlideSupplier<T> <: GlideSupplier<T> {
    private var instance: Option<T> = Option<T>.None;
    private let mtx = ReentrantMutex();

    public DefaultGlideSupplier(let supplier: GlideSupplier<T>) {

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

public class GlideSuppliers {
    private GlideSuppliers() {}

    public static func memorize<T>(supplier: GlideSupplier<T>): GlideSupplier<T> {
        return DefaultGlideSupplier<T>(supplier);
    }
}


