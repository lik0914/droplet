/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2023-2024. All rights resvered.
 */
 
package droplet.droplet

public interface ResourceDecoder<T, Z> {
    func handles(data: T, options: DropletOptions): Bool

    func decode(source: T, width: Int64, height: Int64, options: DropletOptions): Z

    func setTransformation(transformation: Option<AnyTransformation>): Unit
}
