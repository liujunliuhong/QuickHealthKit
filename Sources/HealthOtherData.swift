//
//  HealthOtherData.swift
//  QuickHealthKit
//
//  Created by dfsx6 on 2024/4/19.
//

import Foundation

public class HealthOtherData: CustomStringConvertible, Codable {
    
    /// RMSSD(ms)
    public let rmssd: Int?
    
    /// NN50
    public let nn50: Int?
    
    /// pNN50(%)(没有乘100)
    public let pnn50: Double?
    
    /// Mean RR(ms)
    public let meanRR: Int?
    
    /// MxDMn(ms)
    public let mxdmn: Int?
    
    /// CV(无单位)
    public let cv: Int?
    
    public enum CodingKeys: String, CodingKey {
        case rmssd = "RMSSD"
        case nn50 = "NN50"
        case pnn50 = "pNN50"
        case meanRR = "MeanRR"
        case mxdmn = "MxDMn"
        case cv = "CV"
    }
    
    public init(rmssd: Int?, nn50: Int?, pnn50: Double?, meanRR: Int?, mxdmn: Int?, cv: Int?) {
        self.rmssd = rmssd
        self.nn50 = nn50
        self.pnn50 = pnn50
        self.meanRR = meanRR
        self.mxdmn = mxdmn
        self.cv = cv
    }
    
    public var description: String {
        do {
            let jsonData = try JSONEncoder().encode(self)
            let json = try JSONSerialization.jsonObject(with: jsonData, options: [.fragmentsAllowed, .mutableContainers])
            return "\(json)"
        } catch {
            return ""
        }
    }
}
