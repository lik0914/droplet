/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2023-2024. All rights resvered.
 */
 
package glide

public interface ResourceDecoder<T, Z> {
    func handles(data: T, options: GlideOptions): Bool

    func decode(source: T, width: Int64, height: Int64, options: GlideOptions): Z

    func setTransformation(transformation: Option<AnyTransformation>): Unit
}
