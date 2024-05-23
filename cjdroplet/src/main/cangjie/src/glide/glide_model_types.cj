package glide

from std import fs.*

public interface ModelTypes<T> {
    func load(model: Model): T

    func load(model: fs.Path): T
}

