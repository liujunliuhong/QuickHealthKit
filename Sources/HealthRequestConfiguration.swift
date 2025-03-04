//
//  HealthRequestConfiguration.swift
//  QuickHealthKit
//
//  Created by Jun Liu on 2025/2/28.
//

import Foundation

public final class HealthRequestConfiguration {
    
    /// 是否允许请求HRV（SDNN）
    public var allowRequestHRV: Bool = false
    /// 是否允许请求HRV关联的其他数据
    public var allowRequestHRVOtherData: Bool = false
    /// 是否允许请求HR
    public var allowRequestHR: Bool = false
    /// 是否允许请求RHR
    public var allowRequestRHR: Bool = false
    /// 是否允许请求Step
    public var allowRequestStep: Bool = false
    /// 是否允许请求收缩压
    public var allowRequestBloodPressureSystolic: Bool = false
    /// 是否允许请求舒张压
    public var allowRequestBloodPressureDiastolic: Bool = false
    /// 是否允许请求体重
    public var allowRequestBodyMass: Bool = false
    /// 是否允许请求胰岛素
    public var allowRequestInsulin: Bool = false
    /// 是否允许请求血糖
    public var allowRequestBloodGlucose: Bool = false
    
    public static let `default` = HealthRequestConfiguration()
    
    private init() {
        
    }
}
