#
# Be sure to run `pod lib lint HMCDownloadManager.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'HMCDownloadManager'
  s.version          = '0.1.0'
  s.summary          = 'HMCDownloadManager is a wrapper supporting downloading multiple files within a singleton object'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
Download multiple files concurrently (same or not same URL). We can set maximumDownloadItem for number of maximum items can be downloaded concurrently. We can choose between background (items can be downloaded when app is in background) or default download manager. Callback each block for each item in different queues.
                       DESC

  s.homepage         = 'https://github.com/hmchuong/iOS-ObjectiveC-HMCDownloadManager'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Chuong M. Huynh' => 'minhchuong.itus@gmail.com' }
  s.source           = { :git => 'https://github.com/hmchuong/iOS-ObjectiveC-HMCDownloadManager.git', :tag => s.version.to_s }

  s.ios.deployment_target = '8.0'

  s.source_files = 'HMCDownloadManager/Classes/**/*'

  # s.resource_bundles = {
  #   'HMCDownloadManager' => ['HMCDownloadManager/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  s.frameworks = 'UIKit'
end
