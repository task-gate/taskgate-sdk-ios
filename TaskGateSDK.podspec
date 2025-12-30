Pod::Spec.new do |s|
  s.name             = 'TaskGateSDK'
  s.version          = '1.0.1'
  s.summary          = 'Official TaskGate Partner SDK for iOS'
  s.description      = <<-DESC
Enable your app to provide micro-tasks for TaskGate users. When a user tries to open
a blocked app, TaskGate can redirect them to your app to complete a quick task before
allowing access.

The TaskGate SDK allows partner apps to:
- Receive task requests from TaskGate with task details
- Signal readiness when your app is loaded (cold boot complete)
- Report completion when the user finishes, cancels, or chooses to stay focused
                       DESC

  s.homepage         = 'https://github.com/task-gate/taskgate-sdk-ios'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'TaskGate' => 'partners@taskgate.app' }
  s.source           = { :git => 'https://github.com/task-gate/taskgate-sdk-ios.git', :tag => s.version.to_s }

  s.ios.deployment_target = '13.0'
  s.swift_version = '5.9'

  s.source_files = 'Sources/TaskGateSDK/**/*.swift'

  s.frameworks = 'UIKit', 'Foundation'
end
