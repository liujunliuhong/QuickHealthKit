//
//  ViewController.swift
//  QuickHealthKit
//
//  Created by galaxy on 2024/7/17.
//

import UIKit
import SnapKit
import SwiftDate
import HealthKit

class ViewController: UIViewController {
    
    lazy var testButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle("Test", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .gray
        button.addTarget(self, action: #selector(testAction), for: .touchUpInside)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        view.addSubview(testButton)
        testButton.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(25)
            make.top.equalToSuperview().offset(100)
            make.height.equalTo(55)
        }
        
        // 公历、当前时区、本地化采用英语
        let region = Region(calendar: Calendars.gregorian,
                            zone: Zones.current,
                            locale: Locales.englishUnitedStatesComputer)
        
        SwiftDate.defaultRegion = region
        
        HealthManager.default.setDefaultRegion(region)
        
        let types = [
            HealthSampleType.heartRateVariabilitySDNN,
            HealthSampleType.beatToBeatMeasurements,
            HealthSampleType.sleepAnalysis,
            HealthSampleType.environmentalAudioExposure,
            HealthSampleType.respiratoryRate,
            HealthSampleType.distanceWalkingRunning,
            HealthSampleType.flightsClimbed,
            HealthSampleType.activeEnergyBurned,
            HealthSampleType.mindfulSession,
        ]
        
        HealthManager.default.requestHealthAuthorization(with: types, allowWrite: false) { success in
            
        }
    }
    
    
}


extension ViewController {
    @objc func testAction() {
        print("Start...")
        
        
        let nowDate = Date(year: 2025, month: 3, day: 7, hour: 6, minute: 0)
        // let nowDate = Date.now
        
        let startDate = nowDate.dateAt(.startOfDay).date
        
        let endDate = nowDate.dateAt(.endOfDay).date
        
        HealthManager.default.requestMindfulSession(startDate: startDate, endDate: endDate, ascending: true) { results in
            
            //            var sum: NSDecimalNumber = .zero
            for sample in results {
                let sampleStartDate = sample.startDate
                let sampleEndDate = sample.endDate
                
                let sampleStartDateString = sampleStartDate.toString(.custom("yyyy-MM-dd HH:mm"))
                let sampleEndDateString = sampleEndDate.toString(.custom("yyyy-MM-dd HH:mm"))
                
                //print("😄😄😄: \(sampleStartDateString) - \(sampleEndDateString): \(sample.value)")
                print(sample)
                
                //                sum = sum.adding(sample.kj)
            }
            
            //            print("------\(sum.stringValue)")
        }
        
    }
}
/*
 let config = HealthRequestConfiguration.default
 config.allowRequestHRV = true
 config.allowRequestHRVOtherData = true
 
 HealthManager.default.requestHealthData(year: 2025, month: 2, day: 27, configuration: config, ascending: true) { healthData in
 
 for data in healthData.sdnnDatas {
 let date = data.displayDate
 let sdnn = data.sdnn
 let rmssd = data.otherData?.rmssd
 
 let dateString = date.toString(.custom("yyyy-MM-dd HH:mm"))
 
 print("Date: \(dateString), SDNN: \(sdnn), RMSSD: \(rmssd?.description ?? "nil")")
 }
 
 print("End")
 }
 
 
 
 let nowDate = Date(year: 2024, month: 11, day: 22, hour: 8, minute: 0)
 
 let yesterdayDate = nowDate.dateAt(.yesterday)
 
 let startDate = Date(year: yesterdayDate.year, month: yesterdayDate.month, day: yesterdayDate.day, hour: 18, minute: 0)
 
 let endDate = Date(year: nowDate.year, month: nowDate.month, day: nowDate.day, hour: 18, minute: 0)
 
 HealthManager.default.requestSleepAnalysis(startDate: startDate, endDate: endDate, ascending: true) { results in
 
 for sample in results {
 let sampleStartDate = sample.startDate
 let sampleEndDate = sample.endDate
 
 let sampleStartDateString = sampleStartDate.toString(.custom("yyyy-MM-dd HH:mm"))
 let sampleEndDateString = sampleEndDate.toString(.custom("yyyy-MM-dd HH:mm"))
 
 
 
 print("😄😄😄: \(sampleStartDateString) - \(sampleEndDateString): \(sample.value)")
 }
 }
 */
