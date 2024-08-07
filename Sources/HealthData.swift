//
//  HealthData.swift
//  Glycemic
//
//  Created by galaxy on 2023/10/28.
//

import Foundation
import HealthKit

public final class HealthData: Identifiable, Equatable {
    
    public static func == (lhs: HealthData, rhs: HealthData) -> Bool {
        return lhs.id == rhs.id
    }
    
    public private(set) var id = UUID()
    
    /// 开始日期
    public let startDate: Date
    
    /// 结束日期
    public let endDate: Date
    
    /// HRV集合（数据未排序，需手动排序）
    public private(set) var hrvDatas: [HKQuantitySample] = []
    
    /// HR集合（数据未排序，需手动排序）
    public private(set) var hrDatas: [HKQuantitySample] = []
    
    /// RHR集合（数据未排序，需手动排序）
    public private(set) var rhrDatas: [HKQuantitySample] = []
    
    /// Step集合（数据未排序，需手动排序）
    public private(set) var stepDatas: [HKQuantitySample] = []
    
    /// 过去的数据
    public internal(set) var pastDatas: [HealthData] = []
    
    public var displayDate: Date {
        return endDate
    }
    
    public init(startDate: Date, endDate: Date) {
        self.startDate = startDate
        self.endDate = endDate
    }
    
    public func addHrvDatas(_ datas: [HKQuantitySample]) {
        self.hrvDatas = datas
    }
    
    public func addHrDatas(_ datas: [HKQuantitySample]) {
        self.hrDatas = datas
    }
    
    public func addRhrDatas(_ datas: [HKQuantitySample]) {
        self.rhrDatas = datas
    }
    
    public func addStepDatas(_ datas: [HKQuantitySample]) {
        self.stepDatas = datas
    }
    
    /// 平均HRV。如果为nil，表示无数据
    public var avgHRV: Int? {
        return hrvDatas.avgHRV
    }
    
    /// 获取HRV范围
    public var hrvRange: (min: Int, max: Int)? {
        return hrvDatas.hrvRange
    }
    
    /// 获取平均HR。如果为nil，表示无数据
    public var avgHR: Int? {
        return hrDatas.avgHR
    }
    
    /// 获取HR范围
    public var hrRange: (min: Int, max: Int)? {
        return hrDatas.hrRange
    }
    
    /// 获取平均RHR。如果为nil，表示无数据
    public var avgRHR: Int? {
        return rhrDatas.avgRHR
    }
    
    /// 获取RHR范围
    public var rhrRange: (min: Int, max: Int)? {
        return rhrDatas.rhrRange
    }
    
    /// 获取步数
    public var stepCount: Int {
        return stepDatas.stepCount
    }
    
    /// 获取步数范围
    public var stepRange: (min: Int, max: Int)? {
        return stepDatas.stepRange
    }
    
    public var avgOtherData: HealthOtherData? {
        let otherDatas = hrvDatas.map { $0.otherData }.compactMap { $0 }
        
        if otherDatas.isEmpty {
            return nil
        }
        
        func _avg_(values: [Double]) -> Double? {
            if values.isEmpty {
                return nil
            }
            let sum = values.reduce(0, { $0 + $1 })
            return sum / CGFloat(values.count)
        }
        
        // cv
        let cvs = otherDatas.map { $0.cv }.compactMap { $0 }.map { Double($0) }
        let avgCV = _avg_(values: cvs)
        
        // mxdmn
        let mxdmns = otherDatas.map { $0.mxdmn }.compactMap { $0 }.map { Double($0) }
        let avgMxdmn = _avg_(values: mxdmns)
        
        // Mean RR
        let meanRRs = otherDatas.map { $0.meanRR }.compactMap { $0 }.map { Double($0) }
        let avgMeanRR = _avg_(values: meanRRs)
        
        // pnn50
        let pnn50s = otherDatas.map { $0.pnn50 }.compactMap { $0 }.map { Double($0) }
        let avgPnn50 = _avg_(values: pnn50s)
        
        // pnn50
        let nn50s = otherDatas.map { $0.nn50 }.compactMap { $0 }.map { Double($0) }
        let avgNn50 = _avg_(values: nn50s)
        
        // RMSSD
        let rmssds = otherDatas.map { $0.rmssd }.compactMap { $0 }.map { Double($0) }
        let avgRmssd = _avg_(values: rmssds)
        
        return HealthOtherData(rmssd: avgRmssd == nil ? nil : Int(avgRmssd!),
                               nn50: avgNn50 == nil ? nil : Int(avgNn50!),
                               pnn50: avgPnn50,
                               meanRR: avgMeanRR == nil ? nil : Int(avgMeanRR!),
                               mxdmn: avgMxdmn == nil ? nil : Int(avgMxdmn!),
                               cv: avgCV == nil ? nil : Int(avgCV!))
    }
}

fileprivate struct _Key {
    private static var _otherDataKey = "HKQuantitySample.OtherData"
    static let otherDataKey = withUnsafePointer(to: &_Key._otherDataKey, { $0 })
}

extension HKQuantitySample {
    /// 其他数据
    public var otherData: HealthOtherData? {
        get {
            return objc_getAssociatedObject(self, _Key.otherDataKey) as? HealthOtherData
        }
        set {
            objc_setAssociatedObject(self, _Key.otherDataKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}

extension Array where Element == HealthData {
    /// 平均HRV。如果为nil，表示无数据
    public var avgHRV: Int? {
        return flatMap { $0.hrvDatas }.avgHRV
    }
    
    /// 获取HRV范围
    public var hrvRange: (min: Int, max: Int)? {
        return flatMap { $0.hrvDatas }.hrvRange
    }
    
    /// 获取平均HR。如果为nil，表示无数据
    public var avgHR: Int? {
        return flatMap { $0.hrDatas }.avgHR
    }
    
    /// 获取HR范围
    public var hrRange: (min: Int, max: Int)? {
        return flatMap { $0.hrDatas }.hrRange
    }
    
    /// 获取平均RHR。如果为nil，表示无数据
    public var avgRHR: Int? {
        return flatMap { $0.rhrDatas }.avgRHR
    }
    
    /// 获取RHR范围
    public var rhrRange: (min: Int, max: Int)? {
        return flatMap { $0.rhrDatas }.rhrRange
    }
    
    /// 获取步数
    public var stepCount: Int {
        return flatMap { $0.stepDatas }.stepCount
    }
    
    /// 获取步数范围
    public var stepRange: (min: Int, max: Int)? {
        return flatMap { $0.stepDatas }.stepRange
    }
    
    public var avgOtherData: HealthOtherData? {
        let otherDatas = flatMap { $0.hrvDatas }.map { $0.otherData }.compactMap { $0 }
        
        if otherDatas.isEmpty {
            return nil
        }
        
        func _avg_(values: [Double]) -> Double? {
            if values.isEmpty {
                return nil
            }
            let sum = values.reduce(0, { $0 + $1 })
            return sum / CGFloat(values.count)
        }
        
        // cv
        let cvs = otherDatas.map { $0.cv }.compactMap { $0 }.map { Double($0) }
        let avgCV = _avg_(values: cvs)
        
        // mxdmn
        let mxdmns = otherDatas.map { $0.mxdmn }.compactMap { $0 }.map { Double($0) }
        let avgMxdmn = _avg_(values: mxdmns)
        
        // Mean RR
        let meanRRs = otherDatas.map { $0.meanRR }.compactMap { $0 }.map { Double($0) }
        let avgMeanRR = _avg_(values: meanRRs)
        
        // pnn50
        let pnn50s = otherDatas.map { $0.pnn50 }.compactMap { $0 }.map { Double($0) }
        let avgPnn50 = _avg_(values: pnn50s)
        
        // pnn50
        let nn50s = otherDatas.map { $0.nn50 }.compactMap { $0 }.map { Double($0) }
        let avgNn50 = _avg_(values: nn50s)
        
        // RMSSD
        let rmssds = otherDatas.map { $0.rmssd }.compactMap { $0 }.map { Double($0) }
        let avgRmssd = _avg_(values: rmssds)
        
        return HealthOtherData(rmssd: avgRmssd == nil ? nil : Int(avgRmssd!),
                               nn50: avgNn50 == nil ? nil : Int(avgNn50!),
                               pnn50: avgPnn50,
                               meanRR: avgMeanRR == nil ? nil : Int(avgMeanRR!),
                               mxdmn: avgMxdmn == nil ? nil : Int(avgMxdmn!),
                               cv: avgCV == nil ? nil : Int(avgCV!))
    }
}
