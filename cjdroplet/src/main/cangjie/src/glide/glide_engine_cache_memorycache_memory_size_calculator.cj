/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2023-2024. All rights resvered.
 */
 
package glide

// TODO 有可能不用
public class MemorySizeCalculator {

    private static let LOW_MEMORY_BYTE_ARRAY_POOL_DIVISOR: Int32 = 2;

    private let memoryCacheSize: Int32 = 1024*1024;

    public MemorySizeCalculator() {
        // 一些内存大小相关的参数
    }

    /** Returns the recommended memory cache size for the device it is run on in bytes. */
    public func getMemoryCacheSize() {
        return memoryCacheSize;
    }


}
