Pod::Spec.new do |spec|
  spec.name                  = 'SudoDecentralizedIdentity'
  spec.version               = "4.0.0"
  spec.author                = { 'Sudo Platform Engineering' => 'sudoplatform-engineering@anonyome.com' }
  spec.homepage              = 'https://sudoplatform.com'
  spec.summary               = 'Decentralized Identity SDK for the Sudo Platform by Anonyome Labs.'
  spec.license               = { :type => 'Apache License, Version 2.0', :file => 'LICENSE' }
  spec.source                = { :git => 'https://github.com/sudoplatform/sudo-decentralized-identity-ios.git', :tag => "v#{spec.version}" }
  spec.ios.deployment_target = '11.0'
  spec.requires_arc          = true
  spec.swift_version         = '5.0'
  spec.source_files          = 'SudoDecentralizedIdentity/**/*.swift'
  spec.vendored_frameworks   = 'Indy.framework'
end
