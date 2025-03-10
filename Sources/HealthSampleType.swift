//
//  HealthSampleType.swift
//  MyStressMonitor
//
//  Created by dfsx6 on 2024/3/27.
//

import Foundation
import HealthKit

public struct HealthSampleType {
    /// Heart Rate Variability SDNN
    public static var heartRateVariabilitySDNN: HKQuantityType {
        let _type_: HKQuantityType
        if #available(iOS 15.0, watchOS 8.0, *) {
            _type_ = HKQuantityType(.heartRateVariabilitySDNN)
        } else {
            _type_ = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
        }
        return _type_
    }
    
    /// Heart Rate
    public static var heartRate: HKQuantityType {
        let _type_: HKQuantityType
        if #available(iOS 15.0, watchOS 8.0, *) {
            _type_ = HKQuantityType(.heartRate)
        } else {
            _type_ = HKObjectType.quantityType(forIdentifier: .heartRate)!
        }
        return _type_
    }
    
    /// Step Count
    public static var stepCount: HKQuantityType {
        let _type_: HKQuantityType
        if #available(iOS 15.0, watchOS 8.0, *) {
            _type_ = HKQuantityType(.stepCount)
        } else {
            _type_ = HKObjectType.quantityType(forIdentifier: .stepCount)!
        }
        return _type_
    }
    
    /// Resting Heart Rate
    public static var restingHeartRate: HKQuantityType {
        let _type_: HKQuantityType
        if #available(iOS 15.0, watchOS 8.0, *) {
            _type_ = HKQuantityType(.restingHeartRate)
        } else {
            _type_ = HKObjectType.quantityType(forIdentifier: .restingHeartRate)!
        }
        return _type_
    }
    
    /// Beat-to-Beat Measurements
    public static var beatToBeatMeasurements: HKSampleType {
        return HKSeriesType.heartbeat()
    }
    
    /// 高血压
    public static var bloodPressureSystolic: HKQuantityType {
        let _type_: HKQuantityType
        if #available(iOS 15.0, watchOS 8.0, *) {
            _type_ = HKQuantityType(.bloodPressureSystolic)
        } else {
            _type_ = HKObjectType.quantityType(forIdentifier: .bloodPressureSystolic)!
        }
        return _type_
    }
    
    /// 低血压
    public static var bloodPressureDiastolic: HKQuantityType {
        let _type_: HKQuantityType
        if #available(iOS 15.0, watchOS 8.0, *) {
            _type_ = HKQuantityType(.bloodPressureDiastolic)
        } else {
            _type_ = HKObjectType.quantityType(forIdentifier: .bloodPressureDiastolic)!
        }
        return _type_
    }
    
    /// 体重
    public static var bodyMass: HKQuantityType {
        let _type_: HKQuantityType
        if #available(iOS 15.0, watchOS 8.0, *) {
            _type_ = HKQuantityType(.bodyMass)
        } else {
            _type_ = HKObjectType.quantityType(forIdentifier: .bodyMass)!
        }
        return _type_
    }
    
    /// 身高
    public static var height: HKQuantityType {
        let _type_: HKQuantityType
        if #available(iOS 15.0, watchOS 8.0, *) {
            _type_ = HKQuantityType(.height)
        } else {
            _type_ = HKObjectType.quantityType(forIdentifier: .height)!
        }
        return _type_
    }
    
    /// 性别
    public static var sex: HKCharacteristicType {
        let _type_: HKCharacteristicType
        if #available(iOS 15.0, watchOS 8.0, *) {
            _type_ = HKCharacteristicType(.biologicalSex)
        } else {
            _type_ = HKQuantityType.characteristicType(forIdentifier: .biologicalSex)!
        }
        return _type_
    }
    
    /// 出生日期
    public static var dateOfBirth: HKCharacteristicType {
        let _type_: HKCharacteristicType
        if #available(iOS 15.0, watchOS 8.0, *) {
            _type_ = HKCharacteristicType(.dateOfBirth)
        } else {
            _type_ = HKQuantityType.characteristicType(forIdentifier: .dateOfBirth)!
        }
        return _type_
    }
    
    /// Insulin
    public static var insulin: HKQuantityType {
        let _type_: HKQuantityType
        if #available(iOS 15.0, watchOS 8.0, *) {
            _type_ = HKQuantityType(.insulinDelivery)
        } else {
            _type_ = HKObjectType.quantityType(forIdentifier: .insulinDelivery)!
        }
        return _type_
    }
    
    /// Blood Glucose
    public static var bloodGlucose: HKQuantityType {
        let _type_: HKQuantityType
        if #available(iOS 15.0, watchOS 8.0, *) {
            _type_ = HKQuantityType(.bloodGlucose)
        } else {
            _type_ = HKObjectType.quantityType(forIdentifier: .bloodGlucose)!
        }
        return _type_
    }
    
    /// 正念
    public static var mindfulSession: HKCategoryType {
        return HKCategoryType(.mindfulSession)
    }
    
    /// 睡眠
    public static var sleepAnalysis: HKCategoryType {
        return HKCategoryType(.sleepAnalysis)
    }
    
    /// 能量（卡路里）
    public static var activeEnergyBurned: HKQuantityType {
        let _type_: HKQuantityType
        if #available(iOS 15.0, watchOS 8.0, *) {
            _type_ = HKQuantityType(.activeEnergyBurned)
        } else {
            _type_ = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!
        }
        return _type_
    }
    
    /// 声音（DB）
    public static var environmentalAudioExposure: HKQuantityType {
        let _type_: HKQuantityType
        if #available(iOS 15.0, watchOS 8.0, *) {
            _type_ = HKQuantityType(.environmentalAudioExposure)
        } else {
            _type_ = HKObjectType.quantityType(forIdentifier: .environmentalAudioExposure)!
        }
        return _type_
    }
    
    /// 呼吸频率（DB）
    public static var respiratoryRate: HKQuantityType {
        let _type_: HKQuantityType
        if #available(iOS 15.0, watchOS 8.0, *) {
            _type_ = HKQuantityType(.respiratoryRate)
        } else {
            _type_ = HKObjectType.quantityType(forIdentifier: .respiratoryRate)!
        }
        return _type_
    }
    
    /// distanceWalkingRunning
    public static var distanceWalkingRunning: HKQuantityType {
        let _type_: HKQuantityType
        if #available(iOS 15.0, watchOS 8.0, *) {
            _type_ = HKQuantityType(.distanceWalkingRunning)
        } else {
            _type_ = HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!
        }
        return _type_
    }
    
    /// 楼梯数量
    public static var flightsClimbed: HKQuantityType {
        let _type_: HKQuantityType
        if #available(iOS 15.0, watchOS 8.0, *) {
            _type_ = HKQuantityType(.flightsClimbed)
        } else {
            _type_ = HKObjectType.quantityType(forIdentifier: .flightsClimbed)!
        }
        return _type_
    }
}
