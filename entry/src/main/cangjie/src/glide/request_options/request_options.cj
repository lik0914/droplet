package glide.request_options

public class DefaultRequestOptionsFactory <: RequestOptionsFactory {
    public func build(): RequestOptions {
        return RequestOptions()
    }
}

public interface RequestOptionsFactory {

    /** Returns a non-null {@link RequestOptions} object. */
    func build(): RequestOptions;
}

public class RequestOptions <: BaseRequestOptions<RequestOptions> {
    private static var skipMemoryCacheTrueOptions: Option<RequestOptions> = None;
    private static var skipMemoryCacheFalseOptions: Option<RequestOptions> = None;
    private static var fitCenterOptions: Option<RequestOptions> = None;
    private static var centerInsideOptions: Option<RequestOptions> = None;

    public RequestOptions() {
    }

    public func skipMemoryCacheOf(skipMemoryCache: Bool): RequestOptions {
        if (skipMemoryCache) {
            return skipMemoryCacheTrueOptions.getOrDefault({=> 
                let ro = RequestOptions()
                ro.skipMemoryCache(true, ro).autoClone()
            });
        } else {
            return skipMemoryCacheFalseOptions.getOrDefault({=>
                let ro = RequestOptions() 
                ro.skipMemoryCache(false, ro).autoClone()
            });
        }
    }

    public static func fitCenterTransform(): RequestOptions {
        if (match(fitCenterOptions) {
            case Some(x) => false
            case _ => true
        }) {
            var r = RequestOptions()
            fitCenterOptions = r.fitCenter(RequestOptions()).autoClone();
        }
        
        return fitCenterOptions.getOrThrow();
    }

    public static func centerInsideTransform(): RequestOptions {
        if (match(centerInsideOptions) {
            case Some(x) => false
            case _ => true
        }) {
            var r = RequestOptions()
            centerInsideOptions = r.centerInside(RequestOptions()).autoClone();
        }

        return centerInsideOptions.getOrThrow();
    }

    public static func decodeTypeOf(resourceTypeClass: ResourceTypeClass): RequestOptions {
        let t = RequestOptions()
        return t.decode(resourceTypeClass, t);
    }

}
