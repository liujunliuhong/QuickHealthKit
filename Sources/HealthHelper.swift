//
//  HealthHelper.swift
//  MyStressMonitor
//
//  Created by galaxy on 2024/3/28.
//

import Foundation

public struct HealthHelper {
    
}

extension HealthHelper {
    public static func calculateOtherHealthData(timeSinceSeriesStarts: [Double]) -> HealthOtherData? {
        
        if timeSinceSeriesStarts.count <= 1 {
            return nil
        }
        
        var intervals: [Double] = []
        for i in 0..<(timeSinceSeriesStarts.count - 1) {
            intervals.append(timeSinceSeriesStarts[i + 1] - timeSinceSeriesStarts[i])
        }
        
        // HealthLog.Log("[Intervals] \(intervals)")
        
        let rmssd = computeRMSSD(intervals: intervals)
        
        let computeNN50AndPNN50 = computeNN50AndPNN50(intervals: intervals)
        
        let nn50 = computeNN50AndPNN50?.nn50
        let pnn50 = computeNN50AndPNN50?.pnn50
        
        let meanRR = computeMeanRR(intervals: intervals)
        
        let mxdmn = computeMxDMn(intervals: intervals)
        
        let cv = computeCV(intervals: intervals)
        
        return HealthOtherData(rmssd: rmssd, nn50: nn50, pnn50: pnn50, meanRR: meanRR, mxdmn: mxdmn, cv: cv)
    }
}

private func computeRMSSD(intervals: [Double]) -> Int? {
    // 筛选出小于1000的数据
    let intervals = intervals.filter { $0 <= 1000.0 }
    
    if intervals.count <= 1 {
        return nil
    }
    
    // 计算相邻间隔的差值
    var differences: [Double] = []
    for i in 0..<intervals.count - 1 {
        let diff = intervals[i + 1] - intervals[i]
        differences.append(diff)
    }
    
    // 计算差值的平方
    let squaredDifferences = differences.map { pow($0, 2) }
    
    // 计算平均平方差值
    let meanSquaredDifference = squaredDifferences.reduce(0, +) / Double(squaredDifferences.count)
    
    // 计算RMSSD
    let rmssd = sqrt(meanSquaredDifference)
    
    return Int(round(rmssd))
}

private func computeNN50AndPNN50(intervals: [Double]) -> (nn50: Int, pnn50: Double)? {
    
//    let intervals = intervals.filter { $0 <= 1000.0 }
    
    if intervals.count <= 1 {
        return nil
    }
    
    // 计算相邻间隔的差值
    var differences: [Double] = []
    for i in 0..<intervals.count - 1 {
        let diff = intervals[i + 1] - intervals[i]
        differences.append(diff)
    }
    
    // 找出差值大于50的数
    let results = differences.filter { $0 >= 50.0 }
    
    return (results.count, Double(results.count) / Double(differences.count))
}

private func computeMeanRR(intervals: [Double]) -> Int? {
    
    let intervals = intervals.filter { $0 <= 1000.0 }
    
    if intervals.isEmpty {
        return nil
    }
    
    let sum = intervals.reduce(0.0, +)
    
    let avg = sum / Double(intervals.count)
    
    return Int(round(avg))
}

private func computeMxDMn(intervals: [Double]) -> Int? {
    
    let intervals = intervals.filter { $0 <= 1000.0 }
    
    if intervals.isEmpty {
        return nil
    }
    
    guard let max = intervals.max(), let min = intervals.min() else {
        return nil
    }
    
    return Int(round(max - min))
}

private func computeCV(intervals: [Double]) -> Int? {
    let intervals = intervals.filter { $0 <= 1000.0 }
    
    if intervals.count <= 1 {
        return nil
    }
    
    // 计算均值
    let mean = intervals.reduce(0.0, +) / Double(intervals.count)
    
    // 计算每个数值与均值的差的平方，然后求和
    let sumOfSquaredDeviations = intervals.reduce(0.0) { (sum, value) in
        let deviation = value - mean
        return sum + pow(deviation, 2)
    }
    
    // 计算标准差（样本标准差，除以 n-1）
    let sampleVariance = sumOfSquaredDeviations / (Double(intervals.count) - 1)
    let standardDeviation = sqrt(sampleVariance)
    
    let cv = standardDeviation / mean
    
    return Int(round(cv * 100.0))
}
