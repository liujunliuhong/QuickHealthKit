//
//  ViewController.swift
//  QuickHealthKit
//
//  Created by galaxy on 2024/7/17.
//

import UIKit
import SnapKit
import SwiftDate

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
            HealthSampleType.beatToBeatMeasurements
        ]
        
        HealthManager.default.requestHealthAuthorization(with: types, allowWrite: false) { success in
            
        }
    }


}


extension ViewController {
    @objc func testAction() {
        print("Start...")
        
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
    }
}
