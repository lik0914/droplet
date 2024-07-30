/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2023-2024. All rights resvered.
 */
 
package droplet.droplet


public class DecodeHelper {

  private var dropletContext: DropletContext;
  private var model: Model;
  private var width: Int64;
  private var height: Int64;
  private var resourceTypeClass: ResourceTypeClass;
  private var diskCacheProvider: DiskCacheProvider;
  private var options: DropletOptions;
  private var transformations: CachedHashCodeArrayMap<TransformationKey, AnyKey>;
  private var transformationKey: TransformationKey;
  private var isLoadDataSet: Bool = false;
  
  private var signature: AnyKey;
  private var diskCacheStrategy: DiskCacheStrategy ;
  private var isTransformationRequired: Bool = false;
  private var isScaleOnlyOrNoTransform: Bool = false;

  private var dataSource: DataSource

  public init(dropletContext: DropletContext,
      model: Model,
      signature: AnyKey ,
      width: Int64,
      height: Int64,
      diskCacheStrategy: DiskCacheStrategy,
      resourceTypeClass: ResourceTypeClass,
      transformationKey: TransformationKey,
      options: DropletOptions,
      transformations: CachedHashCodeArrayMap<TransformationKey, AnyKey>,
      isTransformationRequired: Bool,
      isScaleOnlyOrNoTransform: Bool,
      diskCacheProvider: DiskCacheProvider) {
       this.dropletContext = dropletContext;
        this.model = model;
        this.signature = signature;
        this.width = width;
        this.height = height;
        this.diskCacheStrategy = diskCacheStrategy;
        this.resourceTypeClass = resourceTypeClass;
        this.diskCacheProvider = diskCacheProvider;
        this.transformationKey = transformationKey;
        this.options = options;
        this.transformations = transformations;
        this.isTransformationRequired = isTransformationRequired;
        this.isScaleOnlyOrNoTransform = isScaleOnlyOrNoTransform;

        this.dataSource = model.getDataSource()
  }

  public func isGif(data: Array<UInt8>): Bool {
    return ImageUtils.getImageType(data) == ImageUtils.ImageFormatGIF
  }

  public func getDrawableResourceParser(): ResourceDecoder<Array<UInt8>, Drawable> {
    return dropletContext.getManager().getDrawableResourceParser()
  }

  public func getDrawableResourceDecoders(): ArrayList<ResourceDecoder<Array<UInt8>, Drawable>> {
    return dropletContext.getManager().getDrawableResourceDecoders()
  }

  public func getPixelMapResourceDecoders(): ArrayList<ResourceDecoder<Array<UInt8>, PixelMap>> {
    return dropletContext.getManager().getPixelMapResourceDecoders()
  }

  public func getDataSource(): DataSource {
    return this.dataSource
  }

  public func getModel(): Model {
    return model
  }

  public func getModelLoaders(): Option<ArrayList<ModelLoader>> {
    match(model.modelType) {
      case ModelType.STRING => Some(dropletContext.getManager().getStringModelLoaders())
      case ModelType.FILE => Some(dropletContext.getManager().getFileModelLoaders())
      case ModelType.GIFDECODER => None
      case _ => None
    }
  }

  public func clear(): Unit {

  }

  public func getDiskCache(): DiskCache {
    return diskCacheProvider.getDiskCache();
  }

  public func getDiskCacheStrategy(): DiskCacheStrategy {
    return diskCacheStrategy;
  }

  public func getOptions(): DropletOptions {
    return options;
  }

  public func getSignature(): AnyKey {
    return signature;
  }

  public func getWidth(): Int64 {
    return width;
  }

  public func getHeight(): Int64 {
    return height;
  }

  public func getArrayPool(): ArrayPool {
      return dropletContext.getArrayPool();
  }

    // getTranscodeClass
  public func getTransformationKey(): TransformationKey {
    return transformationKey;
  }

  public func getResourceTypeClass(): ResourceTypeClass {
    return resourceTypeClass
  }

  public func getScaleOnlyOrNoTransform(): Bool {
    return isScaleOnlyOrNoTransform;
  }

  public func getTransformation(): Option<AnyTransformation> {
    return getTransformation(this.transformationKey)
  }

  public func getTransformation(transformationKey: TransformationKey): Option<AnyTransformation> {
    var result: Option<AnyKey> = transformations.get(transformationKey);

    if (match(result) {
      case Some(x) => false
      case _ => true
    }) {
      if (transformations.isEmpty() && isTransformationRequired) {
        throw DropletException(
            "Missing transformation for  xxxtransforms. If you wish to ignore unknown resource types, use the optional transformation methods.");
      } else {

        if(transformationKey.tType == TransformationKey.TRANSFORMATION_PIXELMAP) {
          return UnitTransformation<PixelMap>.get();
        } else if(transformationKey.tType == TransformationKey.TRANSFORMATION_INPUTSTREAM) {
          return UnitTransformation<InputStream>.get();
        } else if(transformationKey.tType == TransformationKey.TRANSFORMATION_DRAWABLE) {
          return UnitTransformation<PixelMap>.get();
        } else {
          throw DropletException("Missing transformation for  xxxtransforms.")
        }
      }
    }

    if(result.getOrThrow() is AnyTransformation) {
      return result.getOrThrow() as AnyTransformation;
    }
    throw DropletException("Missing transformation for  xxxtransforms.   error  !!!")
  }

  public func isResourceEncoderAvailable(resource: AnyDropletResource): Bool {
    // Gif格式不支持缓存变换后的数据 不需要判断gif
    if(resource is DropletResource<PixelMap> || resource is DropletResource<PixelMapDrawable>) {
      return true
    }
    return false
  }


}

public class InputStreamEncoder <: Encoder<InputStream> {
  private let byteArrayPool: ArrayPool;

  public init(byteArrayPool: ArrayPool) {
    this.byteArrayPool = byteArrayPool;
  }


  public func encode(d: InputStream, file: DropletFile, options: DropletOptions): Bool {

    let buf: Array<UInt8> = byteArrayPool.get(LruArrayPool.STANDARD_BUFFER_SIZE_BYTES);

    var f: File = file.getFile()

    var read: Int64 = 0
    read = d.read(buf)

    // 两种方式性能不确定
    while(read > 0) {
        f.write(buf[0 .. read])
        read = d.read(buf)
    }

    f.close();
    return true;
  }
}

public class UnitTransformation<T> <: Transformation<T> {
  private static let TRANSFORMATION: AnyTransformation = UnitTransformation<T>();

  /**
   * Returns a UnitTransformation for the given type.
   *
   * @param <T> The type of the resource to be transformed.
   */
  public static func get(): Option<AnyTransformation> {
    return TRANSFORMATION
  }

  public func transform(resource: AnyDropletResource, outWidth: Int64, outHeight: Int64): AnyDropletResource {
    if(resource is DropletResource<T>) {
      let r: DropletResource<T> = (resource as DropletResource<T>).getOrThrow()
      return (transform(r, outWidth, outHeight) as AnyDropletResource).getOrThrow()
    } else {
      return resource
    }
  }

  public func transform(resource: DropletResource<T>, outWidth: Int64, outHeight: Int64): DropletResource<T> {
    return resource;
  }

  public func updateDiskCacheKey(md5: MD5) {
  }

  public func toString(): String {
    return "UnitTransformation"
  }

  public func hashCode(): Int64 {
    return 0
  }

  public operator func ==(that: AnyKey): Bool {
    if(that is UnitTransformation<T>) {
      return true
    } else {
      return false
    }
  }

  public operator func !=(that: AnyKey): Bool {
    if(that is UnitTransformation<T>) {
      return false
    } else {
      return true
    }
  }
}

