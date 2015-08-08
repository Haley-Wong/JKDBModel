Pod::Spec.new do |s|  
  s.name         = "JKDBModel"  
  s.version      = "0.0.1"  
  s.summary      = "一个FMDB的二次封装Model"
  s.homepage     = "https://github.com/Joker-King/JKDBModel"  
  s.license      = 'MIT'  
  s.author       = {'mobileresearch' => 'mobileresearch'}  
  s.source       = { :git => 'https://github.com/mobileresearch/weibo_ios_sdk_sso-oauth.git', :commit => '68defea78942ecc782ffde8f8ffa747872af226d' }  
  s.platform = :ios  
  s.source_files = 'src/SinaWeibo/*.{h,m}'  
  s.resources = "src/SinaWeibo/SinaWeibo.bundle/**/*.png"  
  s.framework  = 'QuartzCore'  
  s.dependency 'JSONKit', '~> 1.4'  
end  