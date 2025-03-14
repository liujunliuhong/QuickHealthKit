//
//  HKQuantitySample+Extension.swift
//  Glycemic
//
//  Created by dfsx6 on 2023/10/20.
//

import Foundation
import HealthKit

private let mmHgUnit = HKUnit.millimeterOfMercury() // mmHg
private let kgUnit = HKUnit.gramUnit(with: .kilo) // kg
private let cmUnit = HKUnit.meterUnit(with: .centi) // cm
private let mUnit = HKUnit.meter() // m
private let mileUnit = HKUnit.mile() // mile - 英里
private let sdnnUnit = HKUnit.secondUnit(with: .milli) // ms
private let heartUnit = HKUnit.count().unitDivided(by: HKUnit.minute()) // times/min
private let countUnit = HKUnit.count() // times
private let internationalUnit = HKUnit.internationalUnit() // U
private let mmol_l_unit = HKUnit.moleUnit(with: HKMetricPrefix.milli, molarMass: HKUnitMolarMassBloodGlucose).unitDivided(by: HKUnit.liter()) // mmoL/L
private let soundLevelUnit = HKUnit.decibelAWeightedSoundPressureLevel() // dB
private let respiratoryRateUnit = HKUnit.count().unitDivided(by: HKUnit.minute()) // times/min
private let kcalUnit = HKUnit.kilocalorie() // kcal
private let kjUnit = HKUnit.jouleUnit(with: .kilo) // kj

private let decimalNumberHandler_1 = NSDecimalNumberHandler(roundingMode: .plain,
                                                            scale: 1,
                                                            raiseOnExactness: false,
                                                            raiseOnOverflow: false,
                                                            raiseOnUnderflow: false,
                                                            raiseOnDivideByZero: false)

private let decimalNumberHandler_2 = NSDecimalNumberHandler(roundingMode: .plain,
                                                            scale: 2,
                                                            raiseOnExactness: false,
                                                            raiseOnOverflow: false,
                                                            raiseOnUnderflow: false,
                                                            raiseOnDivideByZero: false)

extension HKQuantitySample {
    /// 获取SDNN(ms)
    public var sdnn: Int {
        let value = quantity.doubleValue(for: sdnnUnit)
        return Int(round(value))
    }
    
    /// 获取心率(BPM)
    public var hr: Int {
        let value = quantity.doubleValue(for: heartUnit)
        return Int(round(value))
    }
    
    /// 获取静心心率(BPM)
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
    
    /// 获取血压(最高血压、最低血压) (mmHg)
    public var bloodPressure: Double {
        return quantity.doubleValue(for: mmHgUnit)
    }
    
    /// 获取步数
    public var stepCount: Int {
        let value = quantity.doubleValue(for: countUnit)
        return Int(round(value))
    }
    
    /// 获取胰岛素(IU)
    public var insulin: NSDecimalNumber {
        let value = quantity.doubleValue(for: internationalUnit)
        return NSDecimalNumber(value: value).rounding(accordingToBehavior: decimalNumberHandler_1)
    }
    
    /// 获取血糖(mmol/L)
    public var bloodGlucoseMmol: NSDecimalNumber {
        let value = quantity.doubleValue(for: mmol_l_unit)
        return NSDecimalNumber(value: value).rounding(accordingToBehavior: decimalNumberHandler_1)
    }
    
    /// 获取声音（DB）
    public var soundDB: Int {
        let value = quantity.doubleValue(for: soundLevelUnit)
        return Int(round(value))
    }
    
    /// 获取呼吸速率
    public var respiratoryRate: NSDecimalNumber {
        let value = quantity.doubleValue(for: respiratoryRateUnit)
        return NSDecimalNumber(value: value).rounding(accordingToBehavior: decimalNumberHandler_1)
    }
    
    /// 距离（cm）
    public var cmDistance: NSDecimalNumber {
        let value = quantity.doubleValue(for: cmUnit)
        return NSDecimalNumber(value: value).rounding(accordingToBehavior: decimalNumberHandler_1)
    }
    
    /// 距离（mile）
    public var mileDistance: NSDecimalNumber {
        let value = quantity.doubleValue(for: mileUnit)
        return NSDecimalNumber(value: value).rounding(accordingToBehavior: decimalNumberHandler_1)
    }
    
    /// 楼梯数量
    public var floorCount: Int {
        return Int(quantity.doubleValue(for: countUnit))
    }
    
    /// 获取卡路里（kcal）
    public var kcal: NSDecimalNumber {
        let value = quantity.doubleValue(for: kcalUnit)
        return NSDecimalNumber(value: value).rounding(accordingToBehavior: decimalNumberHandler_2)
    }
    
    /// 获取卡路里（kj）
    public var kj: NSDecimalNumber {
        let value = quantity.doubleValue(for: kjUnit)
        return NSDecimalNumber(value: value).rounding(accordingToBehavior: decimalNumberHandler_2)
    }
}

extension HKQuantitySample {
    /// 显示日期
    public var displayDate: Date {
        return endDate
    }
}

extension HKQuantitySample {
    
    /// 根据SDNN构造一个`HKQuantitySample`对象
    public static func getQuantitySample(sdnn: Int, date: Date) -> HKQuantitySample {
        let type = HealthSampleType.heartRateVariabilitySDNN
        let quantity = HKQuantity(unit: sdnnUnit, doubleValue: Double(sdnn))
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
    /// 获取平均SDNN
    public var avgSDNN: Int? {
        if isEmpty {
            return nil
        }
        let total = reduce(0, { $0 + $1.sdnn })
        let result = Double(total) / Double(count)
        return Int(round(result))
    }
    
    /// SDNN范围
    public var sdnnRange: (min: Int, max: Int)? {
        if isEmpty {
            return nil
        }
        let values = map { $0.sdnn }
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
    
    /// 获取平均胰岛素
    public var avgInsulin: NSDecimalNumber? {
        if isEmpty {
            return nil
        }
        let total = reduce(NSDecimalNumber.zero, { $0.adding($1.insulin, withBehavior: decimalNumberHandler_1) })
        let result = total.dividing(by: NSDecimalNumber(value: count), withBehavior: decimalNumberHandler_1)
        return result
    }
    
    /// 获取平均血糖
    public var avgBloodGlucoseMmol: NSDecimalNumber? {
        if isEmpty {
            return nil
        }
        let total = reduce(NSDecimalNumber.zero, { $0.adding($1.bloodGlucoseMmol, withBehavior: decimalNumberHandler_1) })
        let result = total.dividing(by: NSDecimalNumber(value: count), withBehavior: decimalNumberHandler_1)
        return result
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
    
    /// 获取平均Step Count
    public var avgStepCount: Int? {
        if isEmpty {
            return nil
        }
        let total = reduce(0, { $0 + $1.stepCount })
        let result = Double(total) / Double(count)
        return Int(round(result))
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
    
    /// 获取平均声音
    public var avgSoundDB: Int? {
        if isEmpty {
            return nil
        }
        let total = reduce(0, { $0 + $1.soundDB })
        let result = Double(total) / Double(count)
        return Int(round(result))
    }
    
    /// 声音范围
    public var soundDBRange: (min: Int, max: Int)? {
        if isEmpty {
            return nil
        }
        let values = map { $0.soundDB }
        return (values.min()!, values.max()!)
    }
    
    /// 获取平均呼吸速率
    public var avgRespiratoryRate: NSDecimalNumber? {
        if isEmpty {
            return nil
        }
        let total = reduce(NSDecimalNumber.zero, { $0.adding($1.respiratoryRate, withBehavior: decimalNumberHandler_1) })
        let result = total.dividing(by: NSDecimalNumber(value: count), withBehavior: decimalNumberHandler_1)
        return result
    }
    
    /// 呼吸速率范围
    public var respiratoryRateRange: (min: NSDecimalNumber, max: NSDecimalNumber)? {
        if isEmpty {
            return nil
        }
        let values = map { $0.respiratoryRate }
        
        let newValues = values.sorted { d1, d2 -> Bool in
            let r = d1.compare(d2)
            if r == .orderedAscending || r == .orderedSame {
                return true
            }
            return false
        }
        return (newValues.first!, newValues.last!)
    }
    
    /// 获取平均cm距离
    public var avgCmDistance: NSDecimalNumber? {
        if isEmpty {
            return nil
        }
        let total = reduce(NSDecimalNumber.zero, { $0.adding($1.cmDistance, withBehavior: decimalNumberHandler_1) })
        let result = total.dividing(by: NSDecimalNumber(value: count), withBehavior: decimalNumberHandler_1)
        return result
    }
    
    /// cm距离范围
    public var cmDistanceRange: (min: NSDecimalNumber, max: NSDecimalNumber)? {
        if isEmpty {
            return nil
        }
        let values = map { $0.cmDistance }
        
        let newValues = values.sorted { d1, d2 -> Bool in
            let r = d1.compare(d2)
            if r == .orderedAscending || r == .orderedSame {
                return true
            }
            return false
        }
        return (newValues.first!, newValues.last!)
    }
    
    /// 获取平均mile距离
    public var avgMileDistance: NSDecimalNumber? {
        if isEmpty {
            return nil
        }
        let total = reduce(NSDecimalNumber.zero, { $0.adding($1.mileDistance, withBehavior: decimalNumberHandler_1) })
        let result = total.dividing(by: NSDecimalNumber(value: count), withBehavior: decimalNumberHandler_1)
        return result
    }
    
    /// mile距离范围
    public var mileDistanceRange: (min: NSDecimalNumber, max: NSDecimalNumber)? {
        if isEmpty {
            return nil
        }
        let values = map { $0.mileDistance }
        
        let newValues = values.sorted { d1, d2 -> Bool in
            let r = d1.compare(d2)
            if r == .orderedAscending || r == .orderedSame {
                return true
            }
            return false
        }
        return (newValues.first!, newValues.last!)
    }
    
    /// 楼梯数量范围
    public var floorCountRange: (min: Int, max: Int)? {
        if isEmpty {
            return nil
        }
        let values = map { $0.floorCount }
        
        return (values.min()!, values.max()!)
    }
    
    /// 获取平均kcal
    public var avgKcal: NSDecimalNumber? {
        if isEmpty {
            return nil
        }
        let total = reduce(NSDecimalNumber.zero, { $0.adding($1.kcal, withBehavior: decimalNumberHandler_1) })
        let result = total.dividing(by: NSDecimalNumber(value: count), withBehavior: decimalNumberHandler_1)
        return result
    }
    
    /// 卡路里范围（kcal）
    public var kcalRange: (min: NSDecimalNumber, max: NSDecimalNumber)? {
        if isEmpty {
            return nil
        }
        let values = map { $0.kcal }
        
        let newValues = values.sorted { d1, d2 -> Bool in
            let r = d1.compare(d2)
            if r == .orderedAscending || r == .orderedSame {
                return true
            }
            return false
        }
        return (newValues.first!, newValues.last!)
    }
    
    /// 获取平均kj
    public var avgKJ: NSDecimalNumber? {
        if isEmpty {
            return nil
        }
        let total = reduce(NSDecimalNumber.zero, { $0.adding($1.kj, withBehavior: decimalNumberHandler_1) })
        let result = total.dividing(by: NSDecimalNumber(value: count), withBehavior: decimalNumberHandler_1)
        return result
    }
    
    /// 卡路里范围（kj）
    public var kjRange: (min: NSDecimalNumber, max: NSDecimalNumber)? {
        if isEmpty {
            return nil
        }
        let values = map { $0.kj }
        
        let newValues = values.sorted { d1, d2 -> Bool in
            let r = d1.compare(d2)
            if r == .orderedAscending || r == .orderedSame {
                return true
            }
            return false
        }
        return (newValues.first!, newValues.last!)
    }
    
    /// 对`HKQuantitySample`集合排序（升序、降序）
    public func sort(ascending: Bool) -> [Element] {
        if ascending {
            return sorted { data1, data2 -> Bool in
                if data1.displayDate > data2.displayDate {
                    return false
                } else {
                    return true
                }
            }
        } else {
            return sorted { data1, data2 -> Bool in
                if data1.displayDate < data2.displayDate {
                    return false
                } else {
                    return true
                }
            }
        }
    }
}
