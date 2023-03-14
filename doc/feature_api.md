API 接口描述示例Example:
```
/*
* 绑定参数，index从0开始，当index不存在会抛异常
* 可以对同一个位置重复set，后值会覆盖前值
* 参数index-参数所处的位置index
* 参数value-绑定指定下标位置的值，是一个Option类型
* 如果存在该值，将会绑定该值，如果不存在该值，绑定NULL
*/
func setBool(index: Int64, value: Option<Bool>): Unit
```