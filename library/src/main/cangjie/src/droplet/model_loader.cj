/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2023-2024. All rights resvered.
 */
 
package droplet.droplet



public interface ModelLoader {
    func loadModel(t: Any, options: DropletOptions): Option<InputStream>
}

public class FileModelLoader <: ModelLoader {
    public override func loadModel(o: Any, options: DropletOptions): Option<InputStream> {
        if(o is File) {
            return (o as File).getOrThrow()
        } else {
            return None
        }
    }
}

public class StringModelLoader <: ModelLoader {
    public override func loadModel(o: Any, options: DropletOptions): Option<InputStream> {
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
          return getImageFromRawFile(s)
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
        var tls = TlsClientConfig()
        tls.verifyMode = CertificateVerifyMode.TrustAll
        var client = ClientBuilder().readTimeout(Duration.minute*1).tlsConfig(tls).build()
        let resp = client.get(path)
        return Some(resp.body)
    }

    private func getImageFromRawFile(rawFileName: String): Option<InputStream> {
          try{
             let resourceManager = ResourceManager.getResourceManager(getStageContext(Droplet.globalcontext.getOrThrow()))
             let arr:Array<UInt8> = resourceManager.getRawFileContent(rawFileName)
             var byteStream:ByteArrayStream = ByteArrayStream()
             byteStream.write(arr)
             return byteStream
          }catch(e:Exception){
            return None
          }
      }


}
