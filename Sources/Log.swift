import Foundation

public func Log(body: Any? = nil, function: String = __FUNCTION__, line: Int = __LINE__) {
    Log(body == nil ? "" : body, function: function, line: line)
}

public func Log(@autoclosure body: () -> Any, function: String = __FUNCTION__, line: Int = __LINE__) {
#if DEBUG
    print("[\(function) : \(line)] \(body())")
#endif
}