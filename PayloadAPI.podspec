Pod::Spec.new do |spec|
  spec.name         = 'PayloadAPI'
  spec.version      = '0.1.1'
  spec.ios.deployment_target = '10.0'
  spec.swift_versions = '4.2'
  spec.license      = { :type => 'MIT', :file => 'LICENSE' }
  spec.homepage     = 'https://github.com/payload-code/payload-ios'
  spec.authors      = { 'Payload' => 'help@payload.co' }
  spec.summary      = 'Payload library for iOS'
  spec.source       = { :git => 'https://github.com/payload-code/payload-ios.git', :tag => "v#{spec.version}" }
  spec.source_files = 'Payload/*.{h,m,swift}'
  spec.framework    = 'Foundation', 'Network'
  spec.resources    = 'Payload/*.xib', 'Payload/Assets/*.svg'
  spec.resource_bundles    = {
    'Payload' => ['Payload/*.xib']
  }
  spec.dependency 'AMPopTip'
  spec.dependency 'InputMask'
  spec.dependency 'SwiftSVG'
end
