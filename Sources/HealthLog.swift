//
//  HealthLog.swift
//  MyStressMonitor
//
//  Created by galaxy on 2024/3/28.
//

import Foundation

public struct HealthLog {
    
    /// 打印日志
    public static func Log<T>(_ message: T) {
#if DEBUG
        let msg = "[HealthKit] \(message)"
        print(msg)
#endif
    }
}
