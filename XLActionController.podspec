Pod::Spec.new do |spec|
  spec.name     = 'XLActionController'
  spec.version  = '3.0.1'
  spec.license  = 'MIT'
  spec.summary  = 'Fully customizable and extensible action sheet controller written in Swift 3'
  spec.homepage = 'https://github.com/xmartlabs/XLActionController'
  spec.social_media_url = 'http://twitter.com/xmartlabs'
  spec.authors  = { 'Miguel Revetria' => 'miguel@xmartlabs.com', 'Martin Barreto' => 'martin@xmartlabs.com' }
  spec.source   = { :git => 'https://github.com/xmartlabs/XLActionController.git', :tag => spec.version }
  spec.ios.deployment_target = '8.0'
  spec.ios.frameworks = 'UIKit', 'Foundation', 'CoreGraphics'
  spec.requires_arc = true

  # Core subspec
  spec.subspec 'Core' do |core|
    core.source_files = ['Source/*.swift', 'Source/*.xib']
  end

  # One subspec for each example provided by the library
  subspecs = [
    'Periscope',
    'Skype',
    'Spotify',
    'Tweetbot',
    'Twitter',
    'Youtube'
  ]

  subspecs.each do |name|
    spec.subspec name do |subspec|
      subspec.dependency 'XLActionController/Core'
      subspec.source_files = ["Example/CustomActionControllers/#{name}.swift", "Example/CustomActionControllers/ActionData.swift", "Example/CustomActionControllers/#{name}*.xib"]
    end
  end

  # By default install just the Core subspec code
  spec.default_subspec = 'Core'
end
