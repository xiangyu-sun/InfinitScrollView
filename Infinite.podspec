#
# Be sure to run `pod lib lint InfiniteScrollView.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'InfiniteScrollView'
  s.version          = '0.0.4'
  s.summary          = 'A UIKit lib that allow infinite scrolll apun a finite data source'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
InfiniteScrollView is a lightweight, highly customizable open source library designed for iOS developers using UIKit. This library seamlessly integrates with your existing UIKit projects to enable infinite scrolling capabilities, even when working with a finite set of data. It's perfect for enhancing the user experience in applications where lengthy lists or collections can benefit from continuous scroll effects without the end-user ever hitting a "dead end."
                       DESC

  s.homepage         = 'https://github.com/xiangyu-sun/InfinitScrollView'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'xiangyu-sun' => 'luc.alexander.sun@icloud.com' }
  s.source           = { :git => 'https://github.com/xiangyu-sun/InfinitScrollView.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'
  s.swift_versions   = '5.8'

  s.ios.deployment_target = '14.0'

  s.source_files = 'InfiniteScrollView/Classes/**/*'
  
  # s.resource_bundles = {
  #   'InfinitScrollView' => ['InfiniteScrollView/Assets/*.png']
  # }

end
