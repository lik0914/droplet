package glide

from std import fs.*
import glide.model.*
import glide.util.*

public interface ModelTypes<T> {
    func load(model: Model): T

    func load(model: fs.Path): T
}

