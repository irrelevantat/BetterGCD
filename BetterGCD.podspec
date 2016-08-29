#
#  Be sure to run `pod spec lint BetterGCD.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|
  s.name             = 'BetterGCD'
  s.version          = '0.1.1'
  s.summary          = 'BetterGCD 🌪 makes GCD fun! A swifty wrapper for the GCD API'
  s.description      = <<-DESC 
			BetterGCD 🌪 is a highly simplistic Swift wrapper for the GCD API. While being simplistic, it allows usage of priority queues, timer-like repetition, delays, error catching, block chaining and value passing.
			DESC

  s.homepage         = 'https://github.com/Sebastian-Hojas/BetterGCD'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Sebastian Hojas' => 'sebastian.hojas@irrelvant.at' }
  s.source           = { :git => 'https://github.com/Sebastian-Hojas/BetterGCD.git', :tag => s.version }
  
  s.platform	     = :ios, '7.0'
  s.ios.deployment_target = '9.0'
  s.source_files = 'Source/*'

end
