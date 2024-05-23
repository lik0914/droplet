package glide

from std import io.*
from std import fs.*
from net import http.*
from net import tls.*
from std import time.Duration

from ohos import base.*

public interface ModelLoader {
    func loadModel(t: Any, options: GlideOptions): Option<InputStream>
}

public class FileModelLoader <: ModelLoader {
    public override func loadModel(o: Any, options: GlideOptions): Option<InputStream> {
        AppLog.error("FileModelLoader loadModel")
        if(o is File) {
            return (o as File).getOrThrow()
        } else {
            return None
        }
    }
}

public class StringModelLoader <: ModelLoader {
    public override func loadModel(o: Any, options: GlideOptions): Option<InputStream> {
        AppLog.error("StringModelLoader loadModel")
        if(o is String) {
            let s: String = (o as String).getOrThrow()
            getImage(s)
        } else {
            return None
        }
    }

    private func getImage(path: String): Option<InputStream> {
        let s: String = path.trimAscii()
        if(s.startsWith("/")) {
        return getImageFromFile(s)
        } else if(s.startsWith("http")) {
        return getImageFromHttpClient(s)
        } else {
            return None
        }
    }

    private func getImageFromFile(path: String): Option<InputStream> {
        let f: File = File(path, Open(true, false))
        if(f.canRead()) {
            return Some(f)
        }
        return None
    }

    private func getImageFromHttpClient(path: String): Option<InputStream> {
        //适配
        var tls = TlsClientConfig()
        //适配
        tls.verifyMode = CertificateVerifyMode.TrustAll
        //适配
        var client = ClientBuilder().readTimeout(Duration.minute*1).tlsConfig(tls).build()
        let resp = client.get(path)
        return Some(resp.body)
    }


}
