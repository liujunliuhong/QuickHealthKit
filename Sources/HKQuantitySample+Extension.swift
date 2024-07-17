//
//  HKQuantitySample+Extension.swift
//  Glycemic
//
//  Created by dfsx6 on 2023/10/20.
//

import Foundation
import HealthKit

private let mmHgUnit = HKUnit.millimeterOfMercury()
private let kgUnit = HKUnit.gramUnit(with: .kilo)
private let cmUnit = HKUnit.meterUnit(with: .centi)
private let hrvUnit = HKUnit.secondUnit(with: .milli)
private let heartUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
private let stepCountUnit = HKUnit.count()


extension HKQuantitySample {
    /// 获取HRV
    public var hrv: Int {
        let value = quantity.doubleValue(for: hrvUnit)
        return Int(round(value))
    }
    
    /// 获取心率
    public var hr: Int {
        let value = quantity.doubleValue(for: heartUnit)
        return Int(round(value))
    }
    
    /// 获取静心心率
    public var rhr: Int {
        let value = quantity.doubleValue(for: heartUnit)
        return Int(round(value))
    }
    
    /// 获取身高(cm)
    public var cmHeight: Double {
        return quantity.doubleValue(for: cmUnit)
    }
    
    /// 获取体重(kg)
    public var kgWeight: Double {
        return quantity.doubleValue(for: kgUnit)
    }
    
    /// 获取血压(最高血压、最低血压)
    public var bloodPressure: Double {
        return quantity.doubleValue(for: mmHgUnit)
    }
    
    /// 获取步数
    public var stepCount: Int {
        let value = quantity.doubleValue(for: stepCountUnit)
        return Int(round(value))
    }
}

extension HKQuantitySample {
    /// 显示日期
    public var displayDate: Date {
        return endDate
    }
}

extension HKQuantitySample {
    
    /// 根据HRV构造一个`HKQuantitySample`对象
    public static func getQuantitySample(hrv: Int, date: Date) -> HKQuantitySample {
        let type = HealthSampleType.heartRateVariabilitySDNN
        let quantity = HKQuantity(unit: hrvUnit, doubleValue: Double(hrv))
        return HKQuantitySample(type: type,
                                quantity: quantity,
                                start: date,
                                end: date)
    }
    
    /// 根据HR构造一个`HKQuantitySample`对象
    public static func getQuantitySample(hr: Int, date: Date) -> HKQuantitySample? {
        let type = HealthSampleType.heartRate
        let quantity = HKQuantity(unit: heartUnit, doubleValue: Double(hr))
        return HKQuantitySample(type: type,
                                quantity: quantity,
                                start: date,
                                end: date)
    }
    
    public func getNearestHeartRate(with heartRates: [HKQuantitySample]) -> HKQuantitySample? {
        if heartRates.isEmpty {
            return nil
        }
        
        var result = heartRates.first!
        var distance = abs(result.displayDate.timeIntervalSince1970 - displayDate.timeIntervalSince1970)
        for heartRate in heartRates {
            let tmp = abs(heartRate.displayDate.timeIntervalSince1970 - displayDate.timeIntervalSince1970)
            if tmp.isLess(than: distance) {
                distance = tmp
                result = heartRate
            }
        }
        if abs(result.displayDate.timeIntervalSince1970 - displayDate.timeIntervalSince1970) <= 60 * 5 {
            return result
        }
        return nil
    }
}

extension Array where Element == HKQuantitySample {
    /// 获取平均HRV
    public var avgHRV: Int? {
        if isEmpty {
            return nil
        }
        let total = reduce(0, { $0 + $1.hrv })
        let result = Double(total) / Double(count)
        return Int(round(result))
    }
    
    /// HRV范围
    public var hrvRange: (min: Int, max: Int)? {
        if isEmpty {
            return nil
        }
        let values = map { $0.hrv }
        return (values.min()!, values.max()!)
    }
    
    /// 获取平均HR
    public var avgHR: Int? {
        if isEmpty {
            return nil
        }
        let total = reduce(0, { $0 + $1.hr })
        let result = Double(total) / Double(count)
        return Int(round(result))
    }
    
    /// HR范围
    public var hrRange: (min: Int, max: Int)? {
        if isEmpty {
            return nil
        }
        let values = map { $0.hr }
        return (values.min()!, values.max()!)
    }
    
    /// 获取平均RHR
    public var avgRHR: Int? {
        if isEmpty {
            return nil
        }
        let total = reduce(0, { $0 + $1.rhr })
        let result = Double(total) / Double(count)
        return Int(round(result))
    }
    
    /// RHR范围
    public var rhrRange: (min: Int, max: Int)? {
        if isEmpty {
            return nil
        }
        let values = map { $0.rhr }
        return (values.min()!, values.max()!)
    }
    
    /// 获取Step
    public var stepCount: Int {
        if isEmpty {
            return 0
        }
        return reduce(0, { $0 + $1.stepCount })
    }
    
    /// Step范围
    public var stepRange: (min: Int, max: Int)? {
        if isEmpty {
            return nil
        }
        let values = map { $0.stepCount }
        return (values.min()!, values.max()!)
    }
    
    /// 排序（升序、降序）
    public func sort(ascending: Bool) -> [Element] {
        return sorted { data1, data2 -> Bool in
            if ascending {
                if data1.displayDate > data2.displayDate {
                    return false
                } else {
                    return true
                }
            } else {
                if data1.displayDate < data2.displayDate {
                    return false
                } else {
                    return true
                }
            }
        }
    }
}
