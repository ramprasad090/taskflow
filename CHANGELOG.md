## 1.0.1

* Fix test import warnings by updating to use bg_orchestrator package name.
* Add proper MIT license text.

## 1.0.0

* Initial release.
* Unified background task orchestrator for Flutter.
* Android: WorkManager-backed task scheduling with chaining support.
* iOS: BGTaskScheduler-backed task scheduling with simulated chaining.
* Cross-platform: TaskFlow static API, fluent TaskChain builder, sealed TaskResult/TaskStatus.
* Task chaining with sequential and parallel steps.
* Output data passing between chain steps.
* Typed retry policies: exponential, linear, custom.
* Task constraints: network, battery, charging, device idle.
* Priority levels: high (expedited), normal, low.
* Task tagging and tag-based cancellation.
* Real-time progress reporting (0.0–1.0).
* Reactive monitoring via TaskStatus stream.
* One-off and periodic task scheduling.
* Unique task policies: keep, replace.
* Full example app demonstrating all features.
* Comprehensive documentation and pub.dev setup.
