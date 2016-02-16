
Pod::Spec.new do |s|
  s.name         = "FXWebViewCache"
  s.version      = "1.0.0"
  s.summary      = "FXWebViewCache."
  s.description  = <<-DESC
                webViewCache used for iOS 
                   DESC
  s.homepage     = "https://github.com/STT-Ocean/FXWebViewCache"
  s.license      = "MIT"
  s.author             = {"STT-Ocean" => "fenyi2010sun@163.com" }
    s.platform     = :ios, "6.0"
  s.source       = { :git => "https://github.com/STT-Ocean/FXWebViewCache.git", :tag => "1.0.0" }
  s.source_files  = "FXWebViewCache"
   s.requires_arc = true

end
