#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint taskflow.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'taskflow'
  s.version          = '1.0.0'
  s.summary          = 'Cross-platform background task orchestrator for Flutter.'
  s.description      = <<-DESC
TaskFlow schedules and executes background tasks on iOS using BGTaskScheduler.
Supports task chaining, typed retry policies, and progress monitoring.
Pairs with Android WorkManager for unified cross-platform API.
                       DESC
  s.homepage         = 'https://pub.dev/packages/taskflow'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Anthropic' => 'support@anthropic.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'

  # BackgroundTasks framework for BGTaskScheduler
  s.frameworks = 'BackgroundTasks'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
