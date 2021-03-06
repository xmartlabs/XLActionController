Pod::Spec.new do |spec|
  spec.name     = 'XLActionController'
  spec.version  = '5.1.0'
  spec.license  = 'MIT'
  spec.summary  = 'Fully customizable and extensible action sheet controller written in Swift'
  spec.homepage = 'https://github.com/xmartlabs/XLActionController'
  spec.social_media_url = 'https://twitter.com/xmartlabs'
  spec.authors  = { 'Miguel Revetria' => 'miguel@xmartlabs.com', 'Martin Barreto' => 'martin@xmartlabs.com' }
  spec.source   = { :git => 'https://github.com/xmartlabs/XLActionController.git', :tag => spec.version }
  spec.ios.deployment_target = '9.3'
  spec.ios.frameworks = 'UIKit', 'Foundation', 'CoreGraphics'
  spec.requires_arc = true
  spec.swift_version = '5.0'

  # Core subspec
  spec.subspec 'Core' do |core|
    core.source_files = ['Source/*.swift', 'Source/*.xib']
    core.resources = 'Resource/*.xib'
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
      subspec.source_files = ["Example/CustomActionControllers/#{name}/#{name}.swift", "Example/CustomActionControllers/#{name}/#{name}*.xib"]
    end
  end

  # By default install just the Core subspec code
  spec.default_subspec = 'Core'
end
