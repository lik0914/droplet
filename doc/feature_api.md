API 接口描述示例Example:

/*
* 绑 定 参 数 ，index 从 0 开 始 ， 当 index 不 存 在 会 抛 异 常
* 可 以 对 同 一 个 位 置 重 复 set， 后 值 会 覆 盖 前 值
* value 如 果 是 None 表 示 SQL NULL
* 参 数 index - 参 数 所 处 的 位 置 index
* 参 数 value - 绑 定 指 定 下 标 位 置 的 值 ， 是 一 个 Option 类 型 。
* 如 果 存 在 该 值 ， 将 会 绑 定 该 值 ， 如 果 不 存 在 该 值 ，绑 定 NULL
*/

func setBool(index: Int64, value: Option<Bool>): Unit