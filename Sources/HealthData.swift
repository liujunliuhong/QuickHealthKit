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
    
    /// SDNN集合（数据未排序，需手动排序）
    public private(set) var sdnnDatas: [HKQuantitySample] = []
    
    /// HR集合（数据未排序，需手动排序）
    public private(set) var hrDatas: [HKQuantitySample] = []
    
    /// RHR集合（数据未排序，需手动排序）
    public private(set) var rhrDatas: [HKQuantitySample] = []
    
    /// Step集合（数据未排序，需手动排序）
    public private(set) var stepDatas: [HKQuantitySample] = []
    
    /// 高血压集合（数据未排序，需手动排序）
    public private(set) var bloodPressureSystolicDatas: [HKQuantitySample] = []
    
    /// 低血压集合（数据未排序，需手动排序）
    public private(set) var bloodPressureDiastolicDatas: [HKQuantitySample] = []
    
    /// 体重集合（数据未排序，需手动排序）
    public private(set) var bodyMassDatas: [HKQuantitySample] = []
    
    /// 胰岛素集合（数据未排序，需手动排序）
    public private(set) var insulinDatas: [HKQuantitySample] = []
    
    /// 血糖集合（数据未排序，需手动排序）
    public private(set) var bloodGlucoseDatas: [HKQuantitySample] = []
    
    public var displayDate: Date {
        return endDate
    }
    
    public init(startDate: Date, endDate: Date) {
        self.startDate = startDate
        self.endDate = endDate
    }
    
    public func addSDNNDatas(_ datas: [HKQuantitySample]) {
        self.sdnnDatas = datas
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
    
    public func addBloodPressureSystolicDatas(_ datas: [HKQuantitySample]) {
        self.bloodPressureSystolicDatas = datas
    }
    
    public func addBloodPressureDiastolicDatas(_ datas: [HKQuantitySample]) {
        self.bloodPressureDiastolicDatas = datas
    }
    
    public func addBodyMassDatas(_ datas: [HKQuantitySample]) {
        self.bodyMassDatas = datas
    }
    
    public func addInsulinDatas(_ datas: [HKQuantitySample]) {
        self.insulinDatas = datas
    }
    
    public func addBloodGlucoseDatas(_ datas: [HKQuantitySample]) {
        self.bloodGlucoseDatas = datas
    }
    
    /// 平均SDNN。如果为nil，表示无数据
    public var avgSDNN: Int? {
        return sdnnDatas.avgSDNN
    }
    
    /// 获取sdnn范围
    public var sdnnRange: (min: Int, max: Int)? {
        return sdnnDatas.sdnnRange
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
    
    /// 获取平均胰岛素。如果为nil，表示无数据
    public var avgInsulin: NSDecimalNumber? {
        return insulinDatas.avgInsulin
    }
    
    /// 获取平均血糖。如果为nil，表示无数据
    public var avgBloodGlucoseMmol: NSDecimalNumber? {
        return bloodGlucoseDatas.avgBloodGlucoseMmol
    }
    
    public var avgOtherData: HealthOtherData? {
        let otherDatas = sdnnDatas.map { $0.otherData }.compactMap { $0 }
        
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
    /// 平均SDNN。如果为nil，表示无数据
    public var avgSDNN: Int? {
        let values = map { $0.avgSDNN }.compactMap { $0 }.map { Double($0) }
        if let avg = _avg_(values: values) {
            return Int(avg)
        }
        return nil
    }
    
    /// 获取SDNN范围
    public var sdnnRange: (min: Int, max: Int)? {
        let values = map { $0.avgSDNN }.compactMap { $0 }
        if values.isEmpty {
            return nil
        }
        return (values.min()!, values.max()!)
    }
    
    /// 获取平均HR。如果为nil，表示无数据
    public var avgHR: Int? {
        let values = map { $0.avgHR }.compactMap { $0 }.map { Double($0) }
        if let avg = _avg_(values: values) {
            return Int(avg)
        }
        return nil
    }
    
    /// 获取HR范围
    public var hrRange: (min: Int, max: Int)? {
        let values = map { $0.avgHR }.compactMap { $0 }
        if values.isEmpty {
            return nil
        }
        return (values.min()!, values.max()!)
    }
    
    /// 获取平均RHR。如果为nil，表示无数据
    public var avgRHR: Int? {
        let values = map { $0.avgRHR }.compactMap { $0 }.map { Double($0) }
        if let avg = _avg_(values: values) {
            return Int(avg)
        }
        return nil
    }
    
    /// 获取RHR范围
    public var rhrRange: (min: Int, max: Int)? {
        let values = map { $0.avgRHR }.compactMap { $0 }
        if values.isEmpty {
            return nil
        }
        return (values.min()!, values.max()!)
    }
    
    /// 获取步数
    public var stepCount: Int {
        return flatMap { $0.stepDatas }.stepCount
    }
    
    /// 获取步数范围
    public var stepRange: (min: Int, max: Int)? {
        let values = map { $0.stepCount }
        if values.isEmpty {
            return nil
        }
        return (values.min()!, values.max()!)
    }
    
    /// 获取平均胰岛素。如果为nil，表示无数据
    public var avgInsulin: NSDecimalNumber? {
        let values = map { $0.avgInsulin }.compactMap { $0 }
        return _avg_(decimalNumberValues: values, scale: 1)
    }
    
    /// 获取平均血糖。如果为nil，表示无数据
    public var avgBloodGlucoseMmol: NSDecimalNumber? {
        let values = map { $0.avgBloodGlucoseMmol }.compactMap { $0 }
        return _avg_(decimalNumberValues: values, scale: 1)
    }
    
    public var avgOtherData: HealthOtherData? {
        let otherDatas = map { $0.avgOtherData }.compactMap { $0 }
        
        if otherDatas.isEmpty {
            return nil
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

private func _avg_(values: [Double]) -> Double? {
    if values.isEmpty {
        return nil
    }
    let sum = values.reduce(0, { $0 + $1 })
    return sum / CGFloat(values.count)
}

private func _avg_(decimalNumberValues: [NSDecimalNumber], scale: Int16) -> NSDecimalNumber? {
    if decimalNumberValues.isEmpty {
        return nil
    }
    
    let decimalNumberHandler = NSDecimalNumberHandler(roundingMode: .plain,
                                                      scale: scale,
                                                      raiseOnExactness: false,
                                                      raiseOnOverflow: false,
                                                      raiseOnUnderflow: false,
                                                      raiseOnDivideByZero: false)
    
    let total = decimalNumberValues.reduce(NSDecimalNumber.zero, { $0.adding($1, withBehavior: decimalNumberHandler) })
    
    let result = total.dividing(by: NSDecimalNumber(value: decimalNumberValues.count), withBehavior: decimalNumberHandler)
    
    return result
}
