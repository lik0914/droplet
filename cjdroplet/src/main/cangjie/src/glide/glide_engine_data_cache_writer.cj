package glide

public class DataCacheWriter<DataType> <: DiskCacheWriter {
  private let encoder: Encoder<DataType>;
  private let data: DataType;
  private let options: GlideOptions;

  public init(encoder: Encoder<DataType>, data: DataType, options: GlideOptions) {
    this.encoder = encoder;
    this.data = data;
    this.options = options;
  }

  public func write(file: GlideFile): Bool {
    return encoder.encode(data, file, options);
  }
}
