package glide

from net import http.*
from net import tls.*

public class SourceGenerator <: DataFetcherGenerator & FetcherReadyCallback {
    private let helper: DecodeHelper
    private let cb: FetcherReadyCallback
    // volatile
    private var loadDataListIndex: Int64 = -1;
    // volatile
    private var sourceCacheGenerator: Option<DataCacheGenerator> = None;
    //volatile
    private var dataToCache: Option<Any> = None;
    //volatile
    private var originalKey: Option<DataCacheKey> = None;

    public init(helper: DecodeHelper, cb: FetcherReadyCallback) {
        this.helper = helper
        this.cb = cb
    }

    private func startNextBegin(): Bool {
        if (match (dataToCache) {
            case Some(x) => true
            case _ => false
        }) {
            let data: Any = dataToCache.getOrThrow();
            dataToCache = None
            try {
                let isDataInCache: Bool = cacheData(data);
                // If we failed to write the data to cache, the cacheData method will try to decode the
                // original data directly instead of going through the disk cache. Since cacheData has
                // already called our callback at this point, there's nothing more to do but return.
                if (!isDataInCache) {
                    return true;
                }
            // If we were able to write the data to cache successfully, we now need to proceed to call
            // the sourceCacheGenerator below to load the data from cache.
            } catch (e: Exception) {
                // An IOException means we weren't able to write data to cache or we weren't able to rewind
                // it after a disk cache write failed. In either case we can just move on and try the next
                // fetch below.
            }
        }
        return false
    }

    // Concurrent access isn't supported.
    public func startNext(): Bool {
        if (startNextBegin()) {
            return true
        }

        let isNull: Bool = match (sourceCacheGenerator) {
            case Some(x) => true
            case _ => false
        }
        if (isNull) {
            if (sourceCacheGenerator.getOrThrow().startNext()) {
                return true;
            }
        }

        sourceCacheGenerator = None

        let model: Model = helper.getModel()

        let modelLoaders: Option<ArrayList<ModelLoader>> = helper.getModelLoaders()

        if (match (modelLoaders) {
            case Some(x) => false
            case _ => true
        }) {
            return true
        }

        let modelLoader: ModelLoader = modelLoaders.getOrThrow()[0]

        let o: Option<InputStream> = match (model.modelType) {
            case ModelType.STRING => modelLoader.loadModel(model.str, this.helper.getOptions())
            case ModelType.FILE => modelLoader.loadModel(model.file.getFileNoSeek(), this.helper.getOptions())
            case ModelType.GIFDECODER => None
            case _ => None
        }

        var size = match (o.getOrThrow() as Seekable) {
            case Some(v) => v.length
            case None => 0
        }

        if (match (o) {
            case Some(x) => true
            case _ => false
        }) {

            let oo = o.getOrThrow()

            onDataReadyInternal(oo, helper.getDataSource(), ModelKey(model));

            return true
        } else {
            onDataFetcherFailed()
            return true
        }

        return true;
    }

    public func onDataReadyInternal(data: Option<Any>, dataSource: DataSource, sourceKey: Option<AnyKey>): Unit {
        let diskCacheStrategy: DiskCacheStrategy = helper.getDiskCacheStrategy();
        AppLog.error(
            "onDataReadyInternal: ${dataSource} --- ${diskCacheStrategy} : ${diskCacheStrategy.isDataCacheable(dataSource)}"
        )
        if (match (data) {
            case Some(x) => true
            case _ => false
        } && diskCacheStrategy.isDataCacheable(dataSource)) {
            dataToCache = data
            // We might be being called back on someone else's thread. Before doing anything, we should
            // reschedule to get back onto Glide's thread. Then once we're back on Glide's thread, we'll
            // get called again and we can write the retrieved data to cache.
            cb.reschedule();
        } else {
            if (match (originalKey) {
                case Some(x) => true
                case _ => false
            }) {
                cb.onDataFetcherReady(
                    sourceKey.getOrThrow(),
                    data,
                    dataSource
                );
            } else {
                cb.onDataFetcherReady(
                    sourceKey.getOrThrow(),
                    data,
                    dataSource
                );
            }
        }
    }

    /**
     * Returns {@code true} if we were able to cache the data and should try to decode the data
     * directly from cache and {@code false} if we were unable to cache the data and should make an
     * attempt to decode from source.
     */
    private func cacheData(dataToCache: Option<Any>): Bool {
        AppLog.error("cacheData begin")
        let data: Any = dataToCache.getOrThrow()
        if (data is InputStream) {
            AppLog.error("data is InputStream")
            let encoder: Encoder<InputStream> = InputStreamEncoder(helper.getArrayPool())
            let d: InputStream = (data as InputStream).getOrThrow()

            let writer: DataCacheWriter<InputStream> = DataCacheWriter<InputStream>(encoder, d, helper.getOptions());
            let newOriginalKey: DataCacheKey = DataCacheKey(ModelKey(helper.getModel()), helper.getSignature());
            let diskCache: DiskCache = helper.getDiskCache();
            AppLog.error("data put begin")
            diskCache.put(newOriginalKey, writer);

            let cache: Option<GlideFile> = diskCache.get(newOriginalKey)
            if (match (cache) {
                case Some(x) => true
                case _ => false
            }) {
                originalKey = Some(newOriginalKey)
                sourceCacheGenerator = Some(DataCacheGenerator(helper, this))
                // We were able to write the data to cache.
                return true;
            } else {
                cb.onDataFetcherReady(
                    ModelKey(helper.getModel()),
                    data,
                    helper.getDataSource()
                );
            }
        }

        // We failed to write the data to cache.
        return false;

    }

    public func cancel(): Unit {
    }

    public func reschedule(): Unit {
        // We don't expect this to happen, although if we ever need it to we can delegate to our
        // callback.
        throw GlideException("SourceGenerator cannot reschedule !!!");
    }

    // Called from source cache generator.
    public func onDataFetcherReady(sourceKey: AnyKey, data: Option<Any>, dataSource: DataSource): Unit {
        // This data fetcher will be loading from a File and provide the wrong data source, so override
        // with the data source of the original fetcher
        // cb.onDataFetcherReady(sourceKey, data, fetcher, loadData.fetcher.getDataSource(), sourceKey);
        cb.onDataFetcherReady(sourceKey, data, dataSource);
    }

    public func onDataFetcherFailed() {
        cb.onDataFetcherFailed();
    }
}

public class ModelKey <: AnyKey {
    public var model: Model

    public init(model: Model) {
        this.model = model
    }

    public operator func ==(that: AnyKey): Bool {
        return equals(that)
    }

    public operator func !=(that: AnyKey): Bool {
        return !equals(that)
    }

    public func hashCode(): Int64 {
        return model.hashCode();
    }

    public func toString(): String {
        return """
    ModelKey{model=${model}""";
    }

    public func equals(o: AnyKey): Bool {
        if (o is ModelKey) {
            var other: ModelKey = (o as ModelKey).getOrThrow()
            AppLog.error("ModelKey equals ${model} == ${other.model}  -> ${model == other.model}")
            return model == other.model;
        }
        return false;
    }

    public func updateDiskCacheKey(md5: MD5): Unit {
        AppLog.error("ModelKey updateDiskCacheKey: ${model.toString()}")
        md5.MD5Update(model.toString().toArray())
    }
}
