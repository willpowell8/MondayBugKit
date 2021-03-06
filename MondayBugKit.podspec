#
# Be sure to run `pod lib lint MondayBugKit.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'MondayBugKit'
  s.version          = '0.1.0'
  s.summary          = 'Raise bugs into Monday.com easily and quickly'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
This application allows software developers to embed it within the app to support testers and end users directly into monday.com
                       DESC

  s.homepage         = 'https://github.com/willpowell8/MondayBugKit'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'willpowell8' => 'wpowell@deloitte.co.uk' }
  s.source           = { :git => 'https://github.com/willpowell8/MondayBugKit.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '12.0'
  s.dependency 'Eureka'
  s.dependency 'MBProgressHUD'
  s.dependency 'Zip'
  s.dependency 'Alamofire'

  s.source_files = 'MondayBugKit/Classes/**/*'
  
  s.resource_bundles = {
    'MondayBugKit' => ['MondayBugKit/Assets/*.xib']
  }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
