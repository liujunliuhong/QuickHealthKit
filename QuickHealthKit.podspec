
Pod::Spec.new do |s|
  s.name                       = 'QuickHealthKit'
  s.homepage                   = 'https://github.com/liujunliuhong/QuickHealthKit'
  s.summary                    = 'HealthKit Wraper'
  s.description                = 'HealthKit Wraper'
  s.author                     = { 'liujunliuhong' => '1035841713@qq.com' }
  s.version                    = '1.0.0'
  s.source                     = { :git => 'https://github.com/liujunliuhong/QuickHealthKit.git', :tag => s.version.to_s }
  s.platform                   = :ios, '15.0'
  s.license                    = { :type => 'MIT', :file => 'LICENSE' }
  s.module_name                = 'QuickHealthKit'
  s.swift_version              = '5.0'
  s.ios.deployment_target      = '15.0'
  s.watchos.deployment_target  = '9.0'
  s.requires_arc               = true
  s.static_framework           = true
  s.source_files               = 'Sources/*.swift'
  s.dependency 'SwiftDate'
  
end