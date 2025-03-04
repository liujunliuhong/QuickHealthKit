# Uncomment the next line to define a global platform for your project
platform :ios, '15.0'
target 'QuickHealthKit' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!
  pod 'SwiftDate'
  pod 'SnapKit'
  pod 'Galaxy', :git => "https://github.com/liujunliuhong/Galaxy.git"
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '17.0'
      # config.build_settings["EXCLUDED_ARCHS[sdk=iphonesimulator*]"] = "arm64"
    end
  end
end
