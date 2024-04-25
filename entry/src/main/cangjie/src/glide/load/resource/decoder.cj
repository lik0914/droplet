package glide.load.resource

import glide.load.*

public interface ResourceDecoder<T, Z> {
    func handles(data: T, options: GlideOptions): Bool

    func decode(source: T, width: Int64, height: Int64, options: GlideOptions): Z

    func setTransformation(transformation: Option<AnyTransformation>): Unit
}
