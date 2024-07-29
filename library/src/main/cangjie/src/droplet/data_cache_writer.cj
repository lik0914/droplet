/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2023-2024. All rights resvered.
 */
 
package droplet.droplet

public class DataCacheWriter<DataType> <: DiskCacheWriter {
  private let encoder: Encoder<DataType>;
  private let data: DataType;
  private let options: DropletOptions;

  public init(encoder: Encoder<DataType>, data: DataType, options: DropletOptions) {
    this.encoder = encoder;
    this.data = data;
    this.options = options;
  }

  public func write(file: DropletFile): Bool {
    return encoder.encode(data, file, options);
  }
}
