package glide

public enum ByteOrder <: Hashable & Equatable<ByteOrder>{ 
    | LITTLE_ENDIAN
    | BIG_ENDIAN

 public func GetTypeNum(result: ByteOrder): Int64 {
        match (result) {
            case LITTLE_ENDIAN => return 0
            case BIG_ENDIAN => return 1
        }
    }    
    public operator func ==(right: ByteOrder): Bool {
      if(GetTypeNum(right) == GetTypeNum(this)){ 
        true;
      } else {
        false;
      }
    }
    public operator func !=(right: ByteOrder): Bool {
      if (GetTypeNum(right) != GetTypeNum(this)){
        true ;
      } else {
        false 
      }
    } 
    public func hashCode(): Int64 {
        return GetTypeNum(this);
    }          
}