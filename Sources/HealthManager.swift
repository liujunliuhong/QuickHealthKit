//
//  HealthManager.swift
//  Glycemic
//
//  Created by dfsx6 on 2023/10/20.
//

import Foundation
import HealthKit
import SwiftDate

private let queue = DispatchQueue(label: "com.galaxy.Health.HealthData", qos: .unspecified)

public final class HealthManager {
    
    public static let `default` = HealthManager()
    
    private let healthStore: HKHealthStore = HKHealthStore()
    
    private init() {
        // 设置QuickHealthKit的SwiftDate的地域
        // 公历、当前时区、本地化采用英语
        //        SwiftDate.defaultRegion = Region(calendar: Calendars.gregorian,
        //                                         zone: Zones.current,
        //                                         locale: Locales.englishUnitedStatesComputer)
    }
}

extension HealthManager {
    /// 设置默认区域。该方法应该在应用初始化时调用
    public func setDefaultRegion(_ region: Region) {
        SwiftDate.defaultRegion = region
    }
}

extension HealthManager {
    /// 请求健康权限
    public func requestHealthAuthorization(with types: [HKObjectType], allowWrite: Bool = false, completion: ((_ success: Bool) -> Void)?) {
        queue.async {
            HealthLog.Log("Request HealthKit Authorization...")
            
            if !HKHealthStore.isHealthDataAvailable() {
                HealthLog.Log("HealthKit不可用")
                completion?(false)
                return
            }
            
            let newTypes: Set<HKObjectType> = Set(types)
            
            // 这儿要转换的原因：share的类型是HKSampleType，而read的类型是HKObjectType
            // HKObjectType是基类
            var sampleTypes: [HKSampleType] = []
            for type in newTypes {
                if let sampleType = type as? HKSampleType {
                    sampleTypes.append(sampleType)
                }
            }
            
            HealthManager.default.healthStore.requestAuthorization(toShare: allowWrite ? Set(sampleTypes) : nil, read: newTypes) { success, error in
                HealthLog.Log("Request HealthKit Authorization Error: \(error?.localizedDescription ?? "nil")")
                completion?(success)
            }
        }
    }
    
    /// 检查某个ObjectType的授权状态
    /// 该方法检查的是Share的状态。系统没有提供检查Read的状态方法。
    /// 如果用户关闭了Read权限，但是没有关闭Share权限，此时仍然返回的是`sharingAuthorized`状态
    /// 只能通过此方法判断用户是否开启了某个ObjectType的权限
    public func authorizationStatusFor(for type: HKObjectType) -> HKAuthorizationStatus {
        return HealthManager.default.healthStore.authorizationStatus(for: type)
    }
}

extension HealthManager {
    /// 禁用所有更新通知的后台传送
    public func disableAllBackgroundDelivery(completion: ((_ success: Bool, _ error: Error?) -> Void)?) {
        HealthManager.default.healthStore.disableAllBackgroundDelivery { suc, err in
            HealthLog.Log("Disable All Background Delivery: \(suc) - \(err?.localizedDescription ?? "nil")")
            completion?(suc, err)
        }
    }
    
    /// 监控HRV变化
    public func enableBackgroundDeliveryForHeartRateVariability(completion: (() -> Void)?) {
        let sampleType = HealthSampleType.heartRateVariabilitySDNN
        let query = HKObserverQuery(sampleType: sampleType, predicate: nil) { _, completionHandler, error in
            if let error = error {
                HealthLog.Log("HKObserverQuery Error: \(error.localizedDescription)")
                completionHandler()
                return
            }
            completion?()
            completionHandler()
        }
        HealthManager.default.healthStore.execute(query)
        
        HealthManager.default.healthStore.enableBackgroundDelivery(for: sampleType, frequency: .immediate) { success, error in
            HealthLog.Log("Enable Background Delivery For HRV: \(success) - \(error?.localizedDescription ?? "nil")")
        }
    }
}

extension HealthManager {
    /// 获取Beat-to-Beat Measurements
    private func _requestBeatToBeatMeasurements(heartbeatSeries: HKHeartbeatSeriesSample, completion: ((_ timeSinceSeriesStarts: [TimeInterval]) -> Void)?) {
        queue.async {
            var timeSinceSeriesStarts: [TimeInterval] = []
            
            let sem = DispatchSemaphore(value: 0)
            
            let query = HKHeartbeatSeriesQuery(heartbeatSeries: heartbeatSeries) { query, timeSinceSeriesStart, precededByGap, done, error in
                // HealthLog.Log("timeSinceSeriesStart: \(timeSinceSeriesStart), precededByGap: \(precededByGap), done: \(done), error: \(String(describing: error))")
                if error == nil {
                    if done {
                        timeSinceSeriesStarts.append(timeSinceSeriesStart * 1000.0)
                        sem.signal()
                    } else {
                        if !precededByGap {
                            timeSinceSeriesStarts.append(timeSinceSeriesStart * 1000.0)
                        }
                    }
                    /*
                     测试发现：
                     1. 如果precededByGap为true，苹果忽略了该计数
                     */
                } else {
                    sem.signal()
                }
            }
            
            HealthManager.default.healthStore.execute(query)
            
            sem.wait()
            
            completion?(timeSinceSeriesStarts)
        }
    }
    
    /// 获取Beat-to-Beat Measurements
    public func requestBeatToBeatMeasurements(startDate: Date, endDate: Date, ascending: Bool, completion: ((_ otherDatas: [HealthOtherData?]) -> Void)?) {
        queue.async {
            let sampleType = HealthSampleType.beatToBeatMeasurements
            
            let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate)
            
            let timeSortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: ascending)
            let sortDescriptors = [timeSortDescriptor]
            
            let query = HKSampleQuery(sampleType: sampleType,
                                      predicate: predicate,
                                      limit: HKObjectQueryNoLimit,
                                      sortDescriptors: sortDescriptors) { query, samples, error in
                let heartbeatSeriesSamples = (samples ?? []).map { $0 as? HKHeartbeatSeriesSample }.compactMap { $0 }
                
                let group = DispatchGroup()
                
                var infos: [String: HealthOtherData?] = [:]
                
                for sample in heartbeatSeriesSamples {
                    infos[sample.uuid.uuidString] = nil
                }
                
                for heartbeatSeriesSample in heartbeatSeriesSamples {
                    group.enter()
                    HealthManager.default._requestBeatToBeatMeasurements(heartbeatSeries: heartbeatSeriesSample) { timeSinceSeriesStarts in
                        let otherData: HealthOtherData? = HealthHelper.calculateOtherHealthData(timeSinceSeriesStarts: timeSinceSeriesStarts)
                        infos[heartbeatSeriesSample.uuid.uuidString] = otherData
                        group.leave()
                    }
                }
                group.notify(queue: queue) {
                    var otherDatas: [HealthOtherData?] = []
                    
                    for sample in heartbeatSeriesSamples {
                        if let value = infos[sample.uuid.uuidString] {
                            otherDatas.append(value)
                        }
                    }
                    
                    completion?(otherDatas)
                }
            }
            HealthManager.default.healthStore.execute(query)
        }
    }
    
    /// 获取HRV集合
    public func requestHeartRateVariability(startDate: Date, endDate: Date, ascending: Bool, completion: ((_ results: [HKQuantitySample]) -> Void)?) {
        queue.async {
            let quantityType = HealthSampleType.heartRateVariabilitySDNN
            
            let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate)
            
            let timeSortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: ascending)
            let sortDescriptors = [timeSortDescriptor]
            
            let query = HKSampleQuery(sampleType: quantityType,
                                      predicate: predicate,
                                      limit: HKObjectQueryNoLimit,
                                      sortDescriptors: sortDescriptors) { _, results, error in
                if let error = error {
                    
                    HealthLog.Log("=================================")
                    HealthLog.Log("=================================")
                    HealthLog.Log("查询\(startDate.toString(.custom("yyyy-MM-dd HH:mm"))) - \(endDate.toString(.custom("yyyy-MM-dd HH:mm")))【HRV】失败: \(error.localizedDescription)")
                    HealthLog.Log("=================================")
                    HealthLog.Log("=================================")
                    
                    completion?([])
                    return
                }
                
//                let results = (results ?? [])
//                    .map { $0 as? HKQuantitySample }
//                    .compactMap { $0 }
//                    .filter({ sample -> Bool in
//                        // 过滤掉用户输入的数据
//                        if let value = sample.metadata?[HKMetadataKeyWasUserEntered] as? Bool {
//                            return value == false
//                        }
//                        return true
//                    })
                
                let results = (results ?? [])
                    .map { $0 as? HKQuantitySample }
                    .compactMap { $0 }
                
                HealthLog.Log("=================================")
                HealthLog.Log("=================================")
                HealthLog.Log("查询\(startDate.toString(.custom("yyyy-MM-dd HH:mm"))) - \(endDate.toString(.custom("yyyy-MM-dd HH:mm")))的【HRV】成功，数量: \(results.count)")
                HealthLog.Log("=================================")
                HealthLog.Log("=================================")
                
                completion?(results)
            }
            HealthManager.default.healthStore.execute(query)
        }
    }
    
    /// 获取今天的HRV(RMSSD)集合
    public func requestTodayHeartRateVariability(ascending: Bool, completion: ((_ results: [HKQuantitySample]) -> Void)?) {
        let currentDate = Date.now
        let startDate: Date = currentDate.dateAt(.startOfDay).date // 00:00:00 - 零时
        let endDate: Date = currentDate.dateAt(.endOfDay).date // 今天的23:59:59
        HealthManager.default.requestHeartRateVariability(startDate: startDate, endDate: endDate, ascending: ascending) { results in
            completion?(results)
        }
    }
    
    /// 获取HeartRate集合
    public func requestHeartRate(startDate: Date, endDate: Date, ascending: Bool, completion: ((_ results: [HKQuantitySample]) -> Void)?) {
        queue.async {
            let quantityType = HealthSampleType.heartRate
            
            let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate)
            
            let timeSortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: ascending)
            let sortDescriptors = [timeSortDescriptor]
            
            let query = HKSampleQuery(sampleType: quantityType,
                                      predicate: predicate,
                                      limit: HKObjectQueryNoLimit,
                                      sortDescriptors: sortDescriptors) { _, results, error in
                if let error = error {
                    
                    HealthLog.Log("=================================")
                    HealthLog.Log("=================================")
                    HealthLog.Log("查询\(startDate.toString(.custom("yyyy/MM/dd HH:mm"))) - \(endDate.toString(.custom("yyyy/MM/dd HH:mm")))【HeartRate】失败: \(error.localizedDescription)")
                    HealthLog.Log("=================================")
                    HealthLog.Log("=================================")
                    
                    completion?([])
                    return
                }
                
                let results = (results ?? []).map { $0 as? HKQuantitySample }.compactMap { $0 }
                
                HealthLog.Log("=================================")
                HealthLog.Log("=================================")
                HealthLog.Log("查询\(startDate.toString(.custom("yyyy/MM/dd HH:mm"))) - \(endDate.toString(.custom("yyyy/MM/dd HH:mm")))【HeartRate】成功，数量: \(results.count)")
                HealthLog.Log("=================================")
                HealthLog.Log("=================================")
                
                completion?(results)
            }
            HealthManager.default.healthStore.execute(query)
        }
    }
    
    /// 获取RestingHeartRate集合
    public func requestRestingHeartRate(startDate: Date, endDate: Date, ascending: Bool, completion: ((_ results: [HKQuantitySample]) -> Void)?) {
        queue.async {
            let quantityType = HealthSampleType.restingHeartRate
            
            let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate)
            
            let timeSortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: ascending)
            let sortDescriptors = [timeSortDescriptor]
            
            let query = HKSampleQuery(sampleType: quantityType,
                                      predicate: predicate,
                                      limit: HKObjectQueryNoLimit,
                                      sortDescriptors: sortDescriptors) { _, results, error in
                if let error = error {
                    
                    HealthLog.Log("=================================")
                    HealthLog.Log("=================================")
                    HealthLog.Log("查询\(startDate.toString(.custom("yyyy/MM/dd HH:mm"))) - \(endDate.toString(.custom("yyyy/MM/dd HH:mm")))【Resting HeartRate】失败: \(error.localizedDescription)")
                    HealthLog.Log("=================================")
                    HealthLog.Log("=================================")
                    
                    completion?([])
                    return
                }
                
                let results = (results ?? []).map { $0 as? HKQuantitySample }.compactMap { $0 }
                
                HealthLog.Log("=================================")
                HealthLog.Log("=================================")
                HealthLog.Log("查询\(startDate.toString(.custom("yyyy/MM/dd HH:mm"))) - \(endDate.toString(.custom("yyyy/MM/dd HH:mm")))【Resting HeartRate】成功，数量: \(results.count)")
                HealthLog.Log("=================================")
                HealthLog.Log("=================================")
                
                completion?(results)
            }
            HealthManager.default.healthStore.execute(query)
        }
    }
    
    
    /// 获取步数集合
    public func requestSteps(startDate: Date, endDate: Date, ascending: Bool, completion: ((_ results: [HKQuantitySample]) -> Void)?) {
        queue.async {
            
            let quantityType: HKQuantityType = HealthSampleType.stepCount
            
            let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate)
            
            let timeSortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: ascending)
            let sortDescriptors = [timeSortDescriptor]
            
            let query = HKSampleQuery(sampleType: quantityType,
                                      predicate: predicate,
                                      limit: HKObjectQueryNoLimit,
                                      sortDescriptors: sortDescriptors) { _, results, error in
                if let error = error {
                    
                    HealthLog.Log("=================================")
                    HealthLog.Log("=================================")
                    HealthLog.Log("查询\(startDate.toString(.custom("yyyy/MM/dd HH:mm"))) - \(endDate.toString(.custom("yyyy/MM/dd HH:mm")))【StepCount】失败: \(error.localizedDescription)")
                    HealthLog.Log("=================================")
                    HealthLog.Log("=================================")
                    
                    completion?([])
                    return
                }
                
                let results = (results ?? []).map { $0 as? HKQuantitySample }.compactMap { $0 }
                
                HealthLog.Log("=================================")
                HealthLog.Log("=================================")
                HealthLog.Log("查询\(startDate.toString(.custom("yyyy/MM/dd HH:mm"))) - \(endDate.toString(.custom("yyyy/MM/dd HH:mm")))【StepCount】成功，数量: \(results.count)")
                HealthLog.Log("=================================")
                HealthLog.Log("=================================")
                
                completion?(results)
            }
            HealthManager.default.healthStore.execute(query)
        }
    }
    
    /// 获取高血压集合
    public func requestBloodPressureSystolics(startDate: Date, endDate: Date, ascending: Bool, completion: ((_ results: [HKQuantitySample]) -> Void)?) {
        queue.async {
            
            let quantityType: HKQuantityType = HealthSampleType.bloodPressureSystolic
            
            let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate)
            
            let timeSortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: ascending)
            let sortDescriptors = [timeSortDescriptor]
            
            let query = HKSampleQuery(sampleType: quantityType,
                                      predicate: predicate,
                                      limit: HKObjectQueryNoLimit,
                                      sortDescriptors: sortDescriptors) { _, results, error in
                if let error = error {
                    
                    HealthLog.Log("=================================")
                    HealthLog.Log("=================================")
                    HealthLog.Log("查询\(startDate.toString(.custom("yyyy/MM/dd HH:mm"))) - \(endDate.toString(.custom("yyyy/MM/dd HH:mm")))【BloodPressure Systolic】失败: \(error.localizedDescription)")
                    HealthLog.Log("=================================")
                    HealthLog.Log("=================================")
                    
                    completion?([])
                    return
                }
                
                let results = (results ?? []).map { $0 as? HKQuantitySample }.compactMap { $0 }
                
                HealthLog.Log("=================================")
                HealthLog.Log("=================================")
                HealthLog.Log("查询\(startDate.toString(.custom("yyyy/MM/dd HH:mm"))) - \(endDate.toString(.custom("yyyy/MM/dd HH:mm")))【BloodPressure Systolic】成功，数量: \(results.count)")
                HealthLog.Log("=================================")
                HealthLog.Log("=================================")
                
                completion?(results)
            }
            HealthManager.default.healthStore.execute(query)
        }
    }
    
    /// 获取低血压集合
    public func requestBloodPressureDiastolics(startDate: Date, endDate: Date, ascending: Bool, completion: ((_ results: [HKQuantitySample]) -> Void)?) {
        queue.async {
            
            let quantityType: HKQuantityType = HealthSampleType.bloodPressureDiastolic
            
            let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate)
            
            let timeSortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: ascending)
            let sortDescriptors = [timeSortDescriptor]
            
            let query = HKSampleQuery(sampleType: quantityType,
                                      predicate: predicate,
                                      limit: HKObjectQueryNoLimit,
                                      sortDescriptors: sortDescriptors) { _, results, error in
                if let error = error {
                    
                    HealthLog.Log("=================================")
                    HealthLog.Log("=================================")
                    HealthLog.Log("查询\(startDate.toString(.custom("yyyy/MM/dd HH:mm"))) - \(endDate.toString(.custom("yyyy/MM/dd HH:mm")))【BloodPressure Diastolic】失败: \(error.localizedDescription)")
                    HealthLog.Log("=================================")
                    HealthLog.Log("=================================")
                    
                    completion?([])
                    return
                }
                
                let results = (results ?? []).map { $0 as? HKQuantitySample }.compactMap { $0 }
                
                HealthLog.Log("=================================")
                HealthLog.Log("=================================")
                HealthLog.Log("查询\(startDate.toString(.custom("yyyy/MM/dd HH:mm"))) - \(endDate.toString(.custom("yyyy/MM/dd HH:mm")))【BloodPressure Diastolic】成功，数量: \(results.count)")
                HealthLog.Log("=================================")
                HealthLog.Log("=================================")
                
                completion?(results)
            }
            HealthManager.default.healthStore.execute(query)
        }
    }
    
    /// 获取体重集合
    public func requestBodyMasses(startDate: Date, endDate: Date, ascending: Bool, completion: ((_ results: [HKQuantitySample]) -> Void)?) {
        queue.async {
            
            let quantityType: HKQuantityType = HealthSampleType.bodyMass
            
            let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate)
            
            let timeSortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: ascending)
            let sortDescriptors = [timeSortDescriptor]
            
            let query = HKSampleQuery(sampleType: quantityType,
                                      predicate: predicate,
                                      limit: HKObjectQueryNoLimit,
                                      sortDescriptors: sortDescriptors) { _, results, error in
                if let error = error {
                    
                    HealthLog.Log("=================================")
                    HealthLog.Log("=================================")
                    HealthLog.Log("查询\(startDate.toString(.custom("yyyy/MM/dd HH:mm"))) - \(endDate.toString(.custom("yyyy/MM/dd HH:mm")))【BodyMass】失败: \(error.localizedDescription)")
                    HealthLog.Log("=================================")
                    HealthLog.Log("=================================")
                    
                    completion?([])
                    return
                }
                
                let results = (results ?? []).map { $0 as? HKQuantitySample }.compactMap { $0 }
                
                HealthLog.Log("=================================")
                HealthLog.Log("=================================")
                HealthLog.Log("查询\(startDate.toString(.custom("yyyy/MM/dd HH:mm"))) - \(endDate.toString(.custom("yyyy/MM/dd HH:mm")))【BodyMass】成功，数量: \(results.count)")
                HealthLog.Log("=================================")
                HealthLog.Log("=================================")
                
                completion?(results)
            }
            HealthManager.default.healthStore.execute(query)
        }
    }
    
    /// 获取身高集合
    public func requestHeights(startDate: Date, endDate: Date, ascending: Bool, completion: ((_ results: [HKQuantitySample]) -> Void)?) {
        queue.async {
            
            let quantityType: HKQuantityType = HealthSampleType.height
            
            let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate)
            
            let timeSortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: ascending)
            let sortDescriptors = [timeSortDescriptor]
            
            let query = HKSampleQuery(sampleType: quantityType,
                                      predicate: predicate,
                                      limit: HKObjectQueryNoLimit,
                                      sortDescriptors: sortDescriptors) { _, results, error in
                if let error = error {
                    
                    HealthLog.Log("=================================")
                    HealthLog.Log("=================================")
                    HealthLog.Log("查询\(startDate.toString(.custom("yyyy/MM/dd HH:mm"))) - \(endDate.toString(.custom("yyyy/MM/dd HH:mm")))【Height】失败: \(error.localizedDescription)")
                    HealthLog.Log("=================================")
                    HealthLog.Log("=================================")
                    
                    completion?([])
                    return
                }
                
                let results = (results ?? []).map { $0 as? HKQuantitySample }.compactMap { $0 }
                
                HealthLog.Log("=================================")
                HealthLog.Log("=================================")
                HealthLog.Log("查询\(startDate.toString(.custom("yyyy/MM/dd HH:mm"))) - \(endDate.toString(.custom("yyyy/MM/dd HH:mm")))【Height】成功，数量: \(results.count)")
                HealthLog.Log("=================================")
                HealthLog.Log("=================================")
                
                completion?(results)
            }
            HealthManager.default.healthStore.execute(query)
        }
    }
    
    /// 获取性别
    public func requestSex() -> HKBiologicalSex? {
        do {
            let sexType = try HealthManager.default.healthStore.biologicalSex().biologicalSex
            HealthLog.Log("=================================")
            HealthLog.Log("=================================")
            HealthLog.Log("查询【Sex】成功：\(sexType)")
            HealthLog.Log("=================================")
            HealthLog.Log("=================================")
            return sexType
        } catch {
            HealthLog.Log("=================================")
            HealthLog.Log("=================================")
            HealthLog.Log("查询【Sex】失败: \(error.localizedDescription)")
            HealthLog.Log("=================================")
            HealthLog.Log("=================================")
            return nil
        }
    }
    
    /// 请求出生日期
    public func requestDateOfBirth() -> Date? {
        do {
            if let dateOfBirth = try HealthManager.default.healthStore.dateOfBirthComponents().date {
                let msg = dateOfBirth.toString(.custom("yyyy-MM-dd HH:mm:ss"))
                HealthLog.Log("=================================")
                HealthLog.Log("=================================")
                HealthLog.Log("查询【DateOfBirth】成功：\(msg)")
                HealthLog.Log("=================================")
                HealthLog.Log("=================================")
                return dateOfBirth
            } else {
                HealthLog.Log("=================================")
                HealthLog.Log("=================================")
                HealthLog.Log("查询【DateOfBirth】失败：nil")
                HealthLog.Log("=================================")
                HealthLog.Log("=================================")
                return nil
            }
        } catch {
            HealthLog.Log("=================================")
            HealthLog.Log("=================================")
            HealthLog.Log("查询【DateOfBirth】失败: \(error.localizedDescription)")
            HealthLog.Log("=================================")
            HealthLog.Log("=================================")
            return nil
        }
    }
    
    /// 获取胰岛素
    public func requestInsulin(startDate: Date, endDate: Date, ascending: Bool, completion: ((_ results: [HKQuantitySample]) -> Void)?) {
        queue.async {
            
            let quantityType: HKQuantityType = HealthSampleType.insulin
            
            let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate)
            
            let timeSortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: ascending)
            let sortDescriptors = [timeSortDescriptor]
            
            let query = HKSampleQuery(sampleType: quantityType,
                                      predicate: predicate,
                                      limit: HKObjectQueryNoLimit,
                                      sortDescriptors: sortDescriptors) { _, results, error in
                if let error = error {
                    
                    HealthLog.Log("=================================")
                    HealthLog.Log("=================================")
                    HealthLog.Log("查询\(startDate.toString(.custom("yyyy/MM/dd HH:mm"))) - \(endDate.toString(.custom("yyyy/MM/dd HH:mm")))【Insulin】失败: \(error.localizedDescription)")
                    HealthLog.Log("=================================")
                    HealthLog.Log("=================================")
                    
                    completion?([])
                    return
                }
                
                let results = (results ?? []).map { $0 as? HKQuantitySample }.compactMap { $0 }
                
                HealthLog.Log("=================================")
                HealthLog.Log("=================================")
                HealthLog.Log("查询\(startDate.toString(.custom("yyyy/MM/dd HH:mm"))) - \(endDate.toString(.custom("yyyy/MM/dd HH:mm")))【Insulin】成功，数量: \(results.count)")
                HealthLog.Log("=================================")
                HealthLog.Log("=================================")
                
                completion?(results)
            }
            HealthManager.default.healthStore.execute(query)
        }
    }
    
    /// 获取血糖
    public func requestBloodGlucose(startDate: Date, endDate: Date, ascending: Bool, completion: ((_ results: [HKQuantitySample]) -> Void)?) {
        queue.async {
            
            let quantityType: HKQuantityType = HealthSampleType.bloodGlucose
            
            let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate)
            
            let timeSortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: ascending)
            let sortDescriptors = [timeSortDescriptor]
            
            let query = HKSampleQuery(sampleType: quantityType,
                                      predicate: predicate,
                                      limit: HKObjectQueryNoLimit,
                                      sortDescriptors: sortDescriptors) { _, results, error in
                if let error = error {
                    
                    HealthLog.Log("=================================")
                    HealthLog.Log("=================================")
                    HealthLog.Log("查询\(startDate.toString(.custom("yyyy/MM/dd HH:mm"))) - \(endDate.toString(.custom("yyyy/MM/dd HH:mm")))【Blood Glucose】失败: \(error.localizedDescription)")
                    HealthLog.Log("=================================")
                    HealthLog.Log("=================================")
                    
                    completion?([])
                    return
                }
                
                let results = (results ?? []).map { $0 as? HKQuantitySample }.compactMap { $0 }
                
                HealthLog.Log("=================================")
                HealthLog.Log("=================================")
                HealthLog.Log("查询\(startDate.toString(.custom("yyyy/MM/dd HH:mm"))) - \(endDate.toString(.custom("yyyy/MM/dd HH:mm")))【Blood Glucose】成功，数量: \(results.count)")
                HealthLog.Log("=================================")
                HealthLog.Log("=================================")
                
                completion?(results)
            }
            HealthManager.default.healthStore.execute(query)
        }
    }
    
    /// 获取睡眠
    public func requestSleepAnalysis(startDate: Date, endDate: Date, ascending: Bool, completion: ((_ results: [HKCategorySample]) -> Void)?) {
        queue.async {
            
            let categoryType: HKCategoryType = HealthSampleType.sleepAnalysis
            
            let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate)
            
            let timeSortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: ascending)
            let sortDescriptors = [timeSortDescriptor]
            
            let query = HKSampleQuery(sampleType: categoryType,
                                      predicate: predicate,
                                      limit: HKObjectQueryNoLimit,
                                      sortDescriptors: sortDescriptors) { _, results, error in
                if let error = error {
                    
                    HealthLog.Log("=================================")
                    HealthLog.Log("=================================")
                    HealthLog.Log("查询\(startDate.toString(.custom("yyyy/MM/dd HH:mm"))) - \(endDate.toString(.custom("yyyy/MM/dd HH:mm")))【Sleep Analysis】失败: \(error.localizedDescription)")
                    HealthLog.Log("=================================")
                    HealthLog.Log("=================================")
                    
                    completion?([])
                    return
                }
                
                let results = (results ?? []).map { $0 as? HKCategorySample }.compactMap { $0 }
                
                HealthLog.Log("=================================")
                HealthLog.Log("=================================")
                HealthLog.Log("查询\(startDate.toString(.custom("yyyy/MM/dd HH:mm"))) - \(endDate.toString(.custom("yyyy/MM/dd HH:mm")))【Sleep Analysis】成功，数量: \(results.count)")
                HealthLog.Log("=================================")
                HealthLog.Log("=================================")
                
                completion?(results)
            }
            HealthManager.default.healthStore.execute(query)
        }
    }
    
    /// 获取声音
    public func requestEnvironmentalAudioExposure(startDate: Date, endDate: Date, ascending: Bool, completion: ((_ results: [HKQuantitySample]) -> Void)?) {
        queue.async {
            
            let quantityType: HKQuantityType = HealthSampleType.environmentalAudioExposure
            
            let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate)
            
            let timeSortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: ascending)
            let sortDescriptors = [timeSortDescriptor]
            
            let query = HKSampleQuery(sampleType: quantityType,
                                      predicate: predicate,
                                      limit: HKObjectQueryNoLimit,
                                      sortDescriptors: sortDescriptors) { _, results, error in
                if let error = error {
                    
                    HealthLog.Log("=================================")
                    HealthLog.Log("=================================")
                    HealthLog.Log("查询\(startDate.toString(.custom("yyyy/MM/dd HH:mm"))) - \(endDate.toString(.custom("yyyy/MM/dd HH:mm")))【Environmental Audio Exposure】失败: \(error.localizedDescription)")
                    HealthLog.Log("=================================")
                    HealthLog.Log("=================================")
                    
                    completion?([])
                    return
                }
                
                let results = (results ?? []).map { $0 as? HKQuantitySample }.compactMap { $0 }
                
                HealthLog.Log("=================================")
                HealthLog.Log("=================================")
                HealthLog.Log("查询\(startDate.toString(.custom("yyyy/MM/dd HH:mm"))) - \(endDate.toString(.custom("yyyy/MM/dd HH:mm")))【Environmental Audio Exposure】成功，数量: \(results.count)")
                HealthLog.Log("=================================")
                HealthLog.Log("=================================")
                
                completion?(results)
            }
            HealthManager.default.healthStore.execute(query)
        }
    }
    
    /// 呼吸频率
    public func requestRespiratoryRate(startDate: Date, endDate: Date, ascending: Bool, completion: ((_ results: [HKQuantitySample]) -> Void)?) {
        queue.async {
            
            let quantityType: HKQuantityType = HealthSampleType.respiratoryRate
            
            let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate)
            
            let timeSortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: ascending)
            let sortDescriptors = [timeSortDescriptor]
            
            let query = HKSampleQuery(sampleType: quantityType,
                                      predicate: predicate,
                                      limit: HKObjectQueryNoLimit,
                                      sortDescriptors: sortDescriptors) { _, results, error in
                if let error = error {
                    
                    HealthLog.Log("=================================")
                    HealthLog.Log("=================================")
                    HealthLog.Log("查询\(startDate.toString(.custom("yyyy/MM/dd HH:mm"))) - \(endDate.toString(.custom("yyyy/MM/dd HH:mm")))【Respiratory Rate】失败: \(error.localizedDescription)")
                    HealthLog.Log("=================================")
                    HealthLog.Log("=================================")
                    
                    completion?([])
                    return
                }
                
                let results = (results ?? []).map { $0 as? HKQuantitySample }.compactMap { $0 }
                
                HealthLog.Log("=================================")
                HealthLog.Log("=================================")
                HealthLog.Log("查询\(startDate.toString(.custom("yyyy/MM/dd HH:mm"))) - \(endDate.toString(.custom("yyyy/MM/dd HH:mm")))【Respiratory Rate】成功，数量: \(results.count)")
                HealthLog.Log("=================================")
                HealthLog.Log("=================================")
                
                completion?(results)
            }
            HealthManager.default.healthStore.execute(query)
        }
    }
    
    /// distanceWalkingRunning
    public func requestDistanceWalkingRunning(startDate: Date, endDate: Date, ascending: Bool, completion: ((_ results: [HKQuantitySample]) -> Void)?) {
        queue.async {
            
            let quantityType: HKQuantityType = HealthSampleType.distanceWalkingRunning
            
            let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate)
            
            let timeSortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: ascending)
            let sortDescriptors = [timeSortDescriptor]
            
            let query = HKSampleQuery(sampleType: quantityType,
                                      predicate: predicate,
                                      limit: HKObjectQueryNoLimit,
                                      sortDescriptors: sortDescriptors) { _, results, error in
                if let error = error {
                    
                    HealthLog.Log("=================================")
                    HealthLog.Log("=================================")
                    HealthLog.Log("查询\(startDate.toString(.custom("yyyy/MM/dd HH:mm"))) - \(endDate.toString(.custom("yyyy/MM/dd HH:mm")))【Distance Walking Running】失败: \(error.localizedDescription)")
                    HealthLog.Log("=================================")
                    HealthLog.Log("=================================")
                    
                    completion?([])
                    return
                }
                
                let results = (results ?? []).map { $0 as? HKQuantitySample }.compactMap { $0 }
                
                HealthLog.Log("=================================")
                HealthLog.Log("=================================")
                HealthLog.Log("查询\(startDate.toString(.custom("yyyy/MM/dd HH:mm"))) - \(endDate.toString(.custom("yyyy/MM/dd HH:mm")))【Distance Walking Running】成功，数量: \(results.count)")
                HealthLog.Log("=================================")
                HealthLog.Log("=================================")
                
                completion?(results)
            }
            HealthManager.default.healthStore.execute(query)
        }
    }
    
    /// 楼梯数量
    public func requestFlightsClimbed(startDate: Date, endDate: Date, ascending: Bool, completion: ((_ results: [HKQuantitySample]) -> Void)?) {
        queue.async {
            
            let quantityType: HKQuantityType = HealthSampleType.flightsClimbed
            
            let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate)
            
            let timeSortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: ascending)
            let sortDescriptors = [timeSortDescriptor]
            
            let query = HKSampleQuery(sampleType: quantityType,
                                      predicate: predicate,
                                      limit: HKObjectQueryNoLimit,
                                      sortDescriptors: sortDescriptors) { _, results, error in
                if let error = error {
                    
                    HealthLog.Log("=================================")
                    HealthLog.Log("=================================")
                    HealthLog.Log("查询\(startDate.toString(.custom("yyyy/MM/dd HH:mm"))) - \(endDate.toString(.custom("yyyy/MM/dd HH:mm")))【Flights Climbed】失败: \(error.localizedDescription)")
                    HealthLog.Log("=================================")
                    HealthLog.Log("=================================")
                    
                    completion?([])
                    return
                }
                
                let results = (results ?? []).map { $0 as? HKQuantitySample }.compactMap { $0 }
                
                HealthLog.Log("=================================")
                HealthLog.Log("=================================")
                HealthLog.Log("查询\(startDate.toString(.custom("yyyy/MM/dd HH:mm"))) - \(endDate.toString(.custom("yyyy/MM/dd HH:mm")))【Flights Climbed】成功，数量: \(results.count)")
                HealthLog.Log("=================================")
                HealthLog.Log("=================================")
                
                completion?(results)
            }
            HealthManager.default.healthStore.execute(query)
        }
    }
    
    /// 能量消耗
    public func requestActiveEnergyBurned(startDate: Date, endDate: Date, ascending: Bool, completion: ((_ results: [HKQuantitySample]) -> Void)?) {
        queue.async {
            
            let quantityType: HKQuantityType = HealthSampleType.activeEnergyBurned
            
            let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate)
            
            let timeSortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: ascending)
            let sortDescriptors = [timeSortDescriptor]
            
            let query = HKSampleQuery(sampleType: quantityType,
                                      predicate: predicate,
                                      limit: HKObjectQueryNoLimit,
                                      sortDescriptors: sortDescriptors) { _, results, error in
                if let error = error {
                    
                    HealthLog.Log("=================================")
                    HealthLog.Log("=================================")
                    HealthLog.Log("查询\(startDate.toString(.custom("yyyy/MM/dd HH:mm"))) - \(endDate.toString(.custom("yyyy/MM/dd HH:mm")))【Active Energy Burned】失败: \(error.localizedDescription)")
                    HealthLog.Log("=================================")
                    HealthLog.Log("=================================")
                    
                    completion?([])
                    return
                }
                
                let results = (results ?? []).map { $0 as? HKQuantitySample }.compactMap { $0 }
                
                HealthLog.Log("=================================")
                HealthLog.Log("=================================")
                HealthLog.Log("查询\(startDate.toString(.custom("yyyy/MM/dd HH:mm"))) - \(endDate.toString(.custom("yyyy/MM/dd HH:mm")))【Active Energy Burned】成功，数量: \(results.count)")
                HealthLog.Log("=================================")
                HealthLog.Log("=================================")
                
                completion?(results)
            }
            HealthManager.default.healthStore.execute(query)
        }
    }
    
    /// 正念
    public func requestMindfulSession(startDate: Date, endDate: Date, ascending: Bool, completion: ((_ results: [HKCategorySample]) -> Void)?) {
        queue.async {
            
            let quantityType: HKCategoryType = HealthSampleType.mindfulSession
            
            let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate)
            
            let timeSortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: ascending)
            let sortDescriptors = [timeSortDescriptor]
            
            let query = HKSampleQuery(sampleType: quantityType,
                                      predicate: predicate,
                                      limit: HKObjectQueryNoLimit,
                                      sortDescriptors: sortDescriptors) { _, results, error in
                if let error = error {
                    
                    HealthLog.Log("=================================")
                    HealthLog.Log("=================================")
                    HealthLog.Log("查询\(startDate.toString(.custom("yyyy/MM/dd HH:mm"))) - \(endDate.toString(.custom("yyyy/MM/dd HH:mm")))【Mindful Session】失败: \(error.localizedDescription)")
                    HealthLog.Log("=================================")
                    HealthLog.Log("=================================")
                    
                    completion?([])
                    return
                }
                
                let results = (results ?? []).map { $0 as? HKCategorySample }.compactMap { $0 }
                
                HealthLog.Log("=================================")
                HealthLog.Log("=================================")
                HealthLog.Log("查询\(startDate.toString(.custom("yyyy/MM/dd HH:mm"))) - \(endDate.toString(.custom("yyyy/MM/dd HH:mm")))【Mindful Session】成功，数量: \(results.count)")
                HealthLog.Log("=================================")
                HealthLog.Log("=================================")
                
                completion?(results)
            }
            HealthManager.default.healthStore.execute(query)
        }
    }
}

extension HealthManager {
    /// 请求某一天的健康数据
    public func requestHealthData(year: Int,
                                  month: Int,
                                  day: Int,
                                  configuration: HealthRequestConfiguration,
                                  ascending: Bool,
                                  completion: ((_ healthData: HealthData) -> Void)?) {
        
        let date = DateInRegion(year: year, month: month, day: day).date
        
        let startDate = date.dateAt(.startOfDay).date // 00:00:00 - 零时
        let endDate = date.dateAt(.endOfDay).date // 23:59:59
        
        HealthManager.default.requestHealthDatasGroupByDay(startDate: startDate,
                                                           endDate: endDate,
                                                           configuration: configuration,
                                                           ascending: ascending) { healthDatas in
            if let data = healthDatas.first {
                completion?(data)
            } else {
                let data = HealthData(startDate: startDate, endDate: endDate)
                completion?(data)
            }
        }
    }
    
    /// 请求健康数据（根据天进行分组）
    public func requestHealthDatasGroupByDay(startDate: Date,
                                             endDate: Date,
                                             configuration: HealthRequestConfiguration,
                                             ascending: Bool,
                                             completion: ((_ healthDatas: [HealthData]) -> Void)?) {
        queue.async {
            let startTime = CFAbsoluteTimeGetCurrent()
            
            var startDate = startDate
            var endDate = endDate
            
            if startDate > endDate {
                (startDate, endDate) = (endDate, startDate)
            }
            
            HealthManager.default.__requestHealthDatas(startDate: startDate,
                                                       endDate: endDate,
                                                       configuration: configuration,
                                                       ascending: ascending) { healthDatas in
                let endTime = CFAbsoluteTimeGetCurrent()
                
                HealthLog.Log("HealthKit - 查询所有健康数据成功🎉🎉🎉🎉🎉")
                HealthLog.Log("HealthKit - 查询所有健康数据耗时🎉🎉🎉🎉🎉: \(endTime - startTime)s")
                
                completion?(healthDatas)
            }
        }
    }
}

extension HealthManager {
    private func __requestHealthDatas(startDate: Date,
                                      endDate: Date,
                                      configuration: HealthRequestConfiguration,
                                      ascending: Bool,
                                      completion: ((_ healthDatas: [HealthData]) -> Void)?) {
        queue.async {
            
            var startDate = startDate
            var endDate = endDate
            
            if startDate > endDate {
                (startDate, endDate) = (endDate, startDate)
            }
            
            var heartRateVariabilitySamples: [HKQuantitySample] = []
            var otherDatas: [HealthOtherData?] = []
            
            var heartRateSamples: [HKQuantitySample] = []
            
            var restingHeartRateSamples: [HKQuantitySample] = []
            
            var stepSamples: [HKQuantitySample] = []
            
            var bloodPressureSystolicSamples: [HKQuantitySample] = []
            var bloodPressureDiastolicSamples: [HKQuantitySample] = []
            
            var bodyMassSamples: [HKQuantitySample] = []
            
            var insulinSamples: [HKQuantitySample] = []
            
            var bloodGlucoseSamples: [HKQuantitySample] = []
            
            let group = DispatchGroup()
            
            if configuration.allowRequestHRV {
                group.enter()
                HealthManager.default.requestHeartRateVariability(startDate: startDate,
                                                                  endDate: endDate,
                                                                  ascending: ascending) { results in
                    heartRateVariabilitySamples = results
                    group.leave()
                }
            }
            
            if configuration.allowRequestHRVOtherData {
                group.enter()
                HealthManager.default.requestBeatToBeatMeasurements(startDate: startDate, endDate: endDate, ascending: ascending) { _otherDatas in
                    otherDatas = _otherDatas
                    group.leave()
                }
            }
            
            if configuration.allowRequestRHR {
                group.enter()
                HealthManager.default.requestRestingHeartRate(startDate: startDate, endDate: endDate, ascending: ascending) { results in
                    restingHeartRateSamples = results
                    group.leave()
                }
            }
            
            
            if configuration.allowRequestHR {
                group.enter()
                HealthManager.default.requestHeartRate(startDate: startDate,
                                                       endDate: endDate,
                                                       ascending: ascending) { results in
                    heartRateSamples = results
                    group.leave()
                }
            }
            
            
            if configuration.allowRequestStep {
                group.enter()
                HealthManager.default.requestSteps(startDate: startDate, endDate: endDate, ascending: ascending) { results in
                    stepSamples = results
                    group.leave()
                }
            }
            
            if configuration.allowRequestBloodPressureSystolic {
                group.enter()
                HealthManager.default.requestBloodPressureSystolics(startDate: startDate, endDate: endDate, ascending: ascending) { results in
                    bloodPressureSystolicSamples = results
                    group.leave()
                }
            }
            
            if configuration.allowRequestBloodPressureDiastolic {
                group.enter()
                HealthManager.default.requestBloodPressureDiastolics(startDate: startDate, endDate: endDate, ascending: ascending) { results in
                    bloodPressureDiastolicSamples = results
                    group.leave()
                }
            }
            if configuration.allowRequestBodyMass {
                group.enter()
                HealthManager.default.requestBodyMasses(startDate: startDate, endDate: endDate, ascending: ascending) { results in
                    bodyMassSamples = results
                    group.leave()
                }
            }
            if configuration.allowRequestInsulin {
                group.enter()
                HealthManager.default.requestInsulin(startDate: startDate, endDate: endDate, ascending: ascending) { results in
                    insulinSamples = results
                    group.leave()
                }
            }
            if configuration.allowRequestBloodGlucose {
                group.enter()
                HealthManager.default.requestBloodGlucose(startDate: startDate, endDate: endDate, ascending: ascending) { results in
                    bloodGlucoseSamples = results
                    group.leave()
                }
            }
            
            group.notify(queue: queue) {
                
                // 处理OtherData
                // 如果是用户输入的的HRV Data，那么HKMetadataKeyWasUserEntered为true，需要过滤掉，否则OtherData会匹配不上
                // 有一个系统HRV Data必有一个Other Data
                if !otherDatas.isEmpty {
                    let samples = heartRateVariabilitySamples.filter { sample -> Bool in
                        let wasUserEntered = (sample.metadata?[HKMetadataKeyWasUserEntered] as? Bool) ?? false
                        return !wasUserEntered
                    }
                    for (index, sample) in samples.enumerated() {
                        var otherData: HealthOtherData?
                        if index >= 0 && index <= otherDatas.count - 1 {
                            otherData = otherDatas[index]
                        }
                        sample.otherData = otherData
                    }
                }
                
                
                
                var startDate = startDate
                var endDate = endDate
                
                if startDate > endDate {
                    (startDate, endDate) = (endDate, startDate)
                }
                
                startDate = startDate.dateAt(.startOfDay).date
                endDate = endDate.dateAt(.endOfDay).date
                
                
                let differenceDayCount = abs(endDate.difference(in: .day, from: startDate) ?? 0)
                
                
                var models: [HealthData] = []
                for i in 0...differenceDayCount {
                    let dayDate = endDate.dateByAdding(-i, .day)
                    let _startDate = dayDate.dateAt(.startOfDay).date
                    let _endDate = dayDate.dateAt(.endOfDay).date
                    let model = HealthData(startDate: _startDate, endDate: _endDate)
                    if ascending {
                        models.insert(model, at: 0)
                    } else {
                        models.append(model)
                    }
                }
                
                func _getInfo(array: [HKQuantitySample]) -> [String: [HKQuantitySample]] {
                    var info: [String: [HKQuantitySample]] = [:]
                    for sample in array {
                        let key = sample.displayDate.toString(.custom("yyyy-MM-dd"))
                        if var _array = info[key] {
                            _array.append(sample)
                            info[key] = _array
                        } else {
                            info[key] = [sample]
                        }
                    }
                    return info
                }
                
                
                var heartRateSampleInfo: [String: [HKQuantitySample]] = [:]
                var stepSampleInfo: [String: [HKQuantitySample]] = [:]
                var restingHeartRateSampleInfo: [String: [HKQuantitySample]] = [:]
                var heartRateVariabilitySampleInfo: [String: [HKQuantitySample]] = [:]
                
                var bloodPressureSystolicSampleInfo: [String: [HKQuantitySample]] = [:]
                var bloodPressureDiastolicSampleInfo: [String: [HKQuantitySample]] = [:]
                var bodyMassSampleInfo: [String: [HKQuantitySample]] = [:]
                
                var insulinSampleInfo: [String: [HKQuantitySample]] = [:]
                var bloodGlucoseSampleInfo: [String: [HKQuantitySample]] = [:]
                
                let sampleInfoGroup = DispatchGroup()
                
                sampleInfoGroup.enter()
                queue.async {
                    heartRateSampleInfo = _getInfo(array: heartRateSamples)
                    sampleInfoGroup.leave()
                }
                
                sampleInfoGroup.enter()
                queue.async {
                    stepSampleInfo = _getInfo(array: stepSamples)
                    sampleInfoGroup.leave()
                }
                
                sampleInfoGroup.enter()
                queue.async {
                    restingHeartRateSampleInfo = _getInfo(array: restingHeartRateSamples)
                    sampleInfoGroup.leave()
                }
                
                sampleInfoGroup.enter()
                queue.async {
                    heartRateVariabilitySampleInfo = _getInfo(array: heartRateVariabilitySamples)
                    sampleInfoGroup.leave()
                }
                
                sampleInfoGroup.enter()
                queue.async {
                    bloodPressureSystolicSampleInfo = _getInfo(array: bloodPressureSystolicSamples)
                    sampleInfoGroup.leave()
                }
                
                sampleInfoGroup.enter()
                queue.async {
                    bloodPressureDiastolicSampleInfo = _getInfo(array: bloodPressureDiastolicSamples)
                    sampleInfoGroup.leave()
                }
                
                sampleInfoGroup.enter()
                queue.async {
                    bodyMassSampleInfo = _getInfo(array: bodyMassSamples)
                    sampleInfoGroup.leave()
                }
                
                sampleInfoGroup.enter()
                queue.async {
                    insulinSampleInfo = _getInfo(array: insulinSamples)
                    sampleInfoGroup.leave()
                }
                
                sampleInfoGroup.enter()
                queue.async {
                    bloodGlucoseSampleInfo = _getInfo(array: bloodGlucoseSamples)
                    sampleInfoGroup.leave()
                }
                
                sampleInfoGroup.notify(queue: queue) {
                    
                    for model in models {
                        let key = model.displayDate.toString(.custom("yyyy-MM-dd"))
                        
                        for (_key, _array) in heartRateSampleInfo {
                            if _key == key {
                                model.addHrDatas(_array)
                            }
                        }
                        
                        for (_key, _array) in stepSampleInfo {
                            if _key == key {
                                model.addStepDatas(_array)
                            }
                        }
                        
                        for (_key, _array) in restingHeartRateSampleInfo {
                            if _key == key {
                                model.addRhrDatas(_array)
                            }
                        }
                        
                        for (_key, _array) in heartRateVariabilitySampleInfo {
                            if _key == key {
                                model.addSDNNDatas(_array)
                            }
                        }
                        
                        for (_key, _array) in bloodPressureSystolicSampleInfo {
                            if _key == key {
                                model.addBloodPressureSystolicDatas(_array)
                            }
                        }
                        
                        for (_key, _array) in bloodPressureDiastolicSampleInfo {
                            if _key == key {
                                model.addBloodPressureDiastolicDatas(_array)
                            }
                        }
                        
                        for (_key, _array) in bodyMassSampleInfo {
                            if _key == key {
                                model.addBodyMassDatas(_array)
                            }
                        }
                        
                        for (_key, _array) in insulinSampleInfo {
                            if _key == key {
                                model.addInsulinDatas(_array)
                            }
                        }
                        
                        for (_key, _array) in bloodGlucoseSampleInfo {
                            if _key == key {
                                model.addBloodGlucoseDatas(_array)
                            }
                        }
                    }
                    
                    completion?(models)
                }
            }
        }
    }
}
