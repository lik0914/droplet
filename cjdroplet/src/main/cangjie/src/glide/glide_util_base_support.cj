package glide

from std import fs.*
from std import io.*
from std import sync.*
from ohos import base.*

public class GlideString <: AnyGlideOptionValue & GlideAny<GlideString> {
  public let str: String
  public init(str: String) {
    this.str = str
  }
  public func toString(): String {
    return str
  }

  public operator func ==(that: AnyGlideOptionValue): Bool {
    if(that is GlideString) {
        return this.str == (that as GlideString).getOrThrow().str
    }
    return false
  }

  public operator func !=(that: AnyGlideOptionValue): Bool {
    if(that is GlideString) {
        return this.str != (that as GlideString).getOrThrow().str
    }
      return true
  }

  public operator func ==(that: GlideString): Bool {
    return this.str == that.str
  }

  public operator func !=(that: GlideString): Bool {
    return this.str != that.str
  }

  public func hashCode(): Int64 {
      return this.str.hashCode()
  }
}

public class GlideInt <: AnyGlideOptionValue {

    public var key: Int64 = 0
    public init(key: Int64) {
        this.key = key
    }

    public operator func ==(that: AnyGlideOptionValue): Bool {
        if(that is GlideInt) {
            return key == (that as GlideInt).getOrThrow().key
        }
        return false;
    }

    public operator func !=(that: AnyGlideOptionValue): Bool {
        if(that is GlideInt) {
            return key != (that as GlideInt).getOrThrow().key
        }
        return true
    }

    public func hashCode(): Int64 {
        return key.hashCode()
    }

    public func toString(): String {
        return "Option{key=${key}}";
    }
}

public interface AnyGlideOptionValue <: GlideAny<AnyGlideOptionValue> {

}

public interface GlideAny<K> <: ToString & Equatable<K> & Hashable {
}

public class GlideFile <: GlideAny<GlideFile> {
    public var filePath: fs.Path
    public var file: Option<File> = None
    public var directory: Option<Directory> = None
    //适配
    //public var stringWriter: Option<StringWriter> = None
    //public var stringReader: Option<StringReader> = None
    public var stringWriter: Option<StringWriter<File>> = None
    public var stringReader: Option<StringReader<File>> = None
    private let mtx = ReentrantMutex()

    public init(){
        this.filePath = fs.Path("")
    }

    public init(path: fs.Path) {
        this.filePath = path
    }

    public init(file: File) {
        this.filePath = file.info.path
        this.file = Some(file)
    }

    public init(path: String) {
        this(fs.Path(path))
    }
    
    public init(parent: String, child: String) {
        this("${parent}/${child}")
    }

    public init(parent: GlideFile, child: String) {
        this(parent.filePath.join(child))
    }

    public init(parent: GlideFile, child: fs.Path) {
        this(parent.filePath.join(child))
    }

    public func openFile() {
        if(Directory.exists(this.filePath) && this.filePath.isDirectory()) {
            this.directory = Some(Directory(this.filePath))
        } else if(File.exists(this.filePath) && this.filePath.isFile()) {
            this.file = Some(File(this.filePath, OpenOption.Open(true, true)))
        } else if(!File.exists(this.filePath)) {
            this.file = Some(File(this.filePath, OpenOption.Create(true)))
        } else {
            throw Exception("openFile: error  file path ${this.filePath}")
        }
    }

    public func safeOpenFile() {
        if(match(this.file) {
            case Some(x) => true
            case _ => false
        }) {

            if(this.file.getOrThrow().isClosed()) {
                openFile()
            }

            // if(!this.file.getOrThrow().isClosed()) {
            //     this.file.getOrThrow().close()
            // }
            // openFile()
        } else {
            openFile()
        }
    }

    public func close(): Unit {
        if(!this.file.getOrThrow().isClosed()) {
            this.file.getOrThrow().close()
        }
    }

    //public func getStringReader(): StringReader {
    public func getStringReader(): StringReader<File> {
        // AppLog.error("getStringReader ${this.filePath}")
        safeOpenFile()
        return StringReader(this.file.getOrThrow())
    }

    //public func getStringWriter(): StringWriter {
    public func getStringWriter(): StringWriter<File> {
        // AppLog.error("getStringWriter ${this.filePath}")
        safeOpenFile()
        this.file.getOrThrow().seek(SeekPosition.End(0))
        return StringWriter(this.file.getOrThrow())
    }

    public func getFile(): File {
        // AppLog.error("getFile ${this.filePath}")
        safeOpenFile()
        this.file.getOrThrow().seek(SeekPosition.End(0))
        return this.file.getOrThrow()
    }

    public func getFileNoSeek(): File {
        safeOpenFile()
        return this.file.getOrThrow()
    }

    public func toByteArrayStream(): ByteArrayStream {
        // AppLog.error("getFile ${this.filePath}")
        let outStream: ByteArrayStream = ByteArrayStream()
        synchronized (mtx) {
            safeOpenFile()
            this.file.getOrThrow().copyTo(outStream)
            this.file.getOrThrow().close()
        }
        return outStream
    }

    public func length(): Int64 {
        return FileInfo(this.filePath).length
    }

    public func isDirectory(): Bool {
        let r = Directory.exists(this.filePath) && this.filePath.isDirectory()
        // AppLog.error("isDirectory:  ${this.filePath} ${r}")
        return r
    }

    public func isFile(): Bool {
        // AppLog.error("isFile ${this.filePath}")
        return File.exists(this.filePath) && this.filePath.isFile()
    }

    public func exists(): Bool {
        // AppLog.error("GlideFile exists ${this.filePath}")
        if(Directory.exists(this.filePath)) {
            return true
        } else if(File.exists(this.filePath)) {
            return true
        }
        return false
    }

    public func delete(): Bool {
        // AppLog.error("GlideFile delete ${this.filePath}")
        if(isFile()) {
            // AppLog.error("GlideFile delete isFile")
            if(match(this.file) {
                case Some(x) => true
                case _ => false
            }) {
                // AppLog.error("GlideFile delete file is not null")
                this.file.getOrThrow().close()
                // AppLog.error("GlideFile delete file deleting")
                File.delete(this.filePath)
                return true
            } else {
                File.delete(this.filePath)
                return true
            }
            
        } else if(isDirectory()) {
            if(match(this.directory) {
                case Some(x) => true
                case _ => false
            }) {
                Directory.delete(this.filePath)
                return true
            }
        }

        return false
    }

    public func renameTo(to: GlideFile): Bool {
        if(!isFile()) {
            return false
        }
        try {
            File.move(this.filePath, to.filePath, false)
        } catch(e: Exception) {
            return false
        }

        return true
    }

    public func mkdirs(): Bool {
        if(isFile()) {
            return false
        }
        if(!Directory.exists(this.filePath)) {
            this.directory = Some(Directory.create(this.filePath, recursive: true))
            return true
        }
        return false
    }

    public func toString(): String {
        return this.filePath.toString()
    }

    public func hashCode(): Int64 {
        return this.filePath.hashCode()
    }

    public operator func ==(that: GlideFile): Bool {
        return this.filePath == that.filePath
    }

    public operator func !=(that: GlideFile): Bool {
        return this.filePath != that.filePath
    }


}
