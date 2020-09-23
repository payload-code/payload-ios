Pod::Spec.new do |spec|
  spec.name         = 'Payload'
  spec.version      = '0.1.0'
  spec.license      = { :type => 'MIT', :file => 'LICENSE' }
  spec.homepage     = 'https://github.com/payload-code/payload-ios'
  spec.authors      = { 'Payload' => 'help@payload.co' }
  spec.summary      = 'Payload library for iOS'
  spec.source       = { :git => 'https://github.com/payload-code/payload-ios.git', :tag => "v#{spec.version}" }
  spec.source_files = 'Payload/*.{h,m,swift,xib}'
  spec.framework    = 'Foundation', 'Network'
  spec.resources    = 'Payload/*.xib', 'Payload/Assets/*.svg'
  spec.resource_bundles = {'Payload' => ['Payload/*.xib']}
  spec.dependency 'AMPopTip'
  spec.dependency 'InputMask'
  spec.dependency 'SwiftSVG'
end
