# TaskGate SDK for iOS

Official iOS SDK for TaskGate partner integration. Enable your app to provide micro-tasks for TaskGate users.

---

## Full Integration Guide

### What You Need vs What SDK Handles

| Component                              | You Handle          | SDK Handles   |
| -------------------------------------- | ------------------- | ------------- |
| **Info.plist URL scheme config**       | ✅ Required         | -             |
| **Pass URL to SDK**                    | ✅ One line         | -             |
| **Parse URL parameters**               | -                   | ✅ Automatic  |
| **Router setup for `/taskgate/start`** | ❌ Not needed       | ✅ SDK parses |
| **Show task UI**                       | ✅ Your design      | -             |
| **Signal ready / completion**          | ✅ Call SDK methods | -             |

### Integration Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                        YOUR APP SETUP                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  1. Info.plist (Platform Config)                                │
│     └── CFBundleURLSchemes for your scheme                      │
│     └── LSApplicationQueriesSchemes: ["taskgate"]               │
│                                                                 │
│  2. App init() or AppDelegate                                   │
│     └── TaskGateSDK.shared.initialize(providerId: "...")        │
│                                                                 │
│  3. .onOpenURL { } or application(_:open:options:)              │
│     └── TaskGateSDK.shared.handleURL(url)  ← One line only!     │
│                                                                 │
│  4. TaskGateSDK.shared.onTaskReceived = { taskInfo in }         │
│     └── Show your task UI                                       │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘

                              ↓

┌─────────────────────────────────────────────────────────────────┐
│                      SDK HANDLES FOR YOU                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ✅ Checks if URL path contains "taskgate"                      │
│  ✅ Parses task_id, callback_url, session_id, app_name          │
│  ✅ Parses additional custom parameters                         │
│  ✅ Stores session state for completion callbacks               │
│  ✅ Sends ready signal to TaskGate                              │
│  ✅ Sends completion with proper URL format                     │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### You DON'T Need

❌ **No router/navigation setup for TaskGate paths:**

```swift
// NOT NEEDED - SDK handles URL parsing
Route("/taskgate/start") { ... }  // ← Don't need this in SwiftUI
path: "/taskgate/start"           // ← Don't need this in GoRouter
```

❌ **No manual URL parameter parsing:**

```swift
// NOT NEEDED - SDK does this
let taskId = url.queryItems["task_id"]      // ← Don't need this
let callbackUrl = url.queryItems["callback_url"]  // ← Don't need this
```

---

## Overview

The TaskGate SDK allows your app to:

- ✅ **Receive task requests** from TaskGate with task details
- ✅ **Signal readiness** when your app is loaded (cold boot complete)
- ✅ **Report completion** when the user finishes, cancels, or chooses to stay focused

### How It Works

```
User Opens Blocked App → TaskGate Redirect → Your Partner App
                                                      ↓
                                               Receive Task
                                                      ↓
                                              Signal Ready
                                                      ↓
                                              Show Task UI
                                                      ↓
                                             User Completes
                                                      ↓
                                           Report Completion
                                                      ↓
                          TaskGate Shows Choice: Open App or Stay Focused
```

---

## Installation

### CocoaPods (Recommended)

Add to your `Podfile`:

```ruby
pod 'TaskGateSDK', '~> 1.0.1'
```

Install:

```bash
pod install
```

### Swift Package Manager

#### Xcode UI

1. File → Add Package Dependencies
2. Enter URL: `https://github.com/task-gate/taskgate-sdk-ios.git`
3. Select version: `1.0.1` or higher

#### Package.swift

```swift
dependencies: [
    .package(url: "https://github.com/task-gate/taskgate-sdk-ios.git", from: "1.0.1")
]
```

---

## Quick Start

### 1. Initialize SDK

**SwiftUI App:**

```swift
import SwiftUI
import TaskGateSDK

@main
struct YourApp: App {
    init() {
        // Initialize with your provider ID
        TaskGateSDK.shared.initialize(providerId: "your_provider_id")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    TaskGateSDK.shared.handleURL(url)
                }
        }
    }
}
```

**UIKit App:**

```swift
import UIKit
import TaskGateSDK

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        // Initialize SDK
        TaskGateSDK.shared.initialize(providerId: "your_provider_id")

        return true
    }

    func application(_ app: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {

        // Handle incoming URLs
        TaskGateSDK.shared.handleURL(url)
        return true
    }
}
```

### 2. Configure URL Scheme

Add to your `Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>yourapp</string>
        </array>
        <key>CFBundleURLName</key>
        <string>com.yourcompany.yourapp</string>
    </dict>
</array>

<key>LSApplicationQueriesSchemes</key>
<array>
    <string>taskgate</string>
</array>
```

### 3. Handle Task Requests

```swift
import TaskGateSDK

class TaskViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Set up task handler
        TaskGateSDK.shared.onTaskReceived = { [weak self] taskInfo in
            self?.handleTask(taskInfo)
        }
    }

    func handleTask(_ taskInfo: TaskGateSDK.TaskInfo) {
        // Your app is loaded, signal ready
        TaskGateSDK.shared.notifyReady()

        // Display task based on taskId
        switch taskInfo.taskId {
        case "breathing_30s":
            showBreathingExercise()
        case "affirmation":
            showAffirmation()
        case "quiz":
            showQuiz()
        default:
            showGenericTask(taskInfo.taskId)
        }
    }

    func onTaskCompleted(userWantsToOpen: Bool) {
        if userWantsToOpen {
            // User completed task and wants to open the blocked app
            TaskGateSDK.shared.reportCompletion(.open)
        } else {
            // User completed task but wants to stay focused
            TaskGateSDK.shared.reportCompletion(.focus)
        }
    }

    func onTaskCancelled() {
        // User cancelled the task
        TaskGateSDK.shared.cancelTask()
    }
}
```

---

## API Reference

### Initialization

#### `initialize(providerId:)`

Initialize the SDK with your provider ID.

```swift
TaskGateSDK.shared.initialize(providerId: "your_provider_id")
```

**Parameters:**

- `providerId`: String - Your unique provider ID from TaskGate

**When to call:** App launch (AppDelegate or App init)

---

### URL Handling

#### `handleURL(_:)`

Parse incoming TaskGate requests.

```swift
TaskGateSDK.shared.handleURL(url)
```

**Parameters:**

- `url`: URL - The URL received from `onOpenURL`

**When to call:** When your app receives a URL (SwiftUI `onOpenURL` or UIKit `application(_:open:options:)`)

---

### Task Lifecycle

#### `onTaskReceived`

Callback triggered when a task is received.

```swift
TaskGateSDK.shared.onTaskReceived = { taskInfo in
    // Handle task
}
```

**Callback Parameter:**

- `taskInfo`: TaskInfo - Contains task details

**When to set:** During view controller setup

---

#### `notifyReady()`

Signal that your app is ready to display the task.

```swift
TaskGateSDK.shared.notifyReady()
```

**When to call:** After your UI is loaded and ready to show the task

**Important:** Call this AFTER receiving the task, when your app has completed cold boot and UI is ready.

---

#### `reportCompletion(_:)`

Report task completion status.

```swift
TaskGateSDK.shared.reportCompletion(.open)  // User wants to open blocked app
TaskGateSDK.shared.reportCompletion(.focus) // User wants to stay focused
```

**Parameters:**

- `status`: CompletionStatus - The outcome of the task

**Completion Status:**

- `.open` - User completed task and wants to access the blocked app
- `.focus` - User completed task but chooses to stay focused
- `.cancelled` - User cancelled/skipped the task

---

#### `cancelTask()`

Shorthand for reporting task cancellation.

```swift
TaskGateSDK.shared.cancelTask()
// Equivalent to: reportCompletion(.cancelled)
```

---

### Data Types

#### `TaskInfo`

Contains information about the task request.

```swift
struct TaskInfo {
    let taskId: String              // Task identifier (e.g., "breathing_30s")
    let sessionId: String            // Session ID for this request
    let callbackUrl: String          // URL to notify TaskGate
    let appName: String?             // Name of blocked app (optional)
    let additionalParams: [String: String] // Extra parameters
}
```

#### `CompletionStatus`

Task completion outcomes.

```swift
enum CompletionStatus {
    case open      // User wants to open the blocked app
    case focus     // User wants to stay focused
    case cancelled // User cancelled the task
}
```

---

## Complete Examples

### SwiftUI Example

```swift
import SwiftUI
import TaskGateSDK

@main
struct PartnerApp: App {
    init() {
        TaskGateSDK.shared.initialize(providerId: "breathing_app_001")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    TaskGateSDK.shared.handleURL(url)
                }
        }
    }
}

struct ContentView: View {
    @State private var showingTask = false
    @State private var currentTask: TaskGateSDK.TaskInfo?

    var body: some View {
        VStack {
            Text("Breathing & Mindfulness App")
                .font(.title)
        }
        .sheet(isPresented: $showingTask) {
            if let task = currentTask {
                TaskView(taskInfo: task, isPresented: $showingTask)
            }
        }
        .onAppear {
            setupTaskHandler()
        }
    }

    func setupTaskHandler() {
        TaskGateSDK.shared.onTaskReceived = { taskInfo in
            currentTask = taskInfo
            showingTask = true

            // Signal app is ready
            TaskGateSDK.shared.notifyReady()
        }
    }
}

struct TaskView: View {
    let taskInfo: TaskGateSDK.TaskInfo
    @Binding var isPresented: Bool

    var body: some View {
        VStack {
            Text("Complete this task")
                .font(.title)

            Text("Task: \(taskInfo.taskId)")
                .padding()

            if let appName = taskInfo.appName {
                Text("You tried to open: \(appName)")
                    .foregroundColor(.gray)
            }

            // Your task UI here
            BreathingExercise()

            HStack {
                Button("Stay Focused") {
                    TaskGateSDK.shared.reportCompletion(.focus)
                    isPresented = false
                }

                Button("Open App") {
                    TaskGateSDK.shared.reportCompletion(.open)
                    isPresented = false
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()

            Button("Cancel") {
                TaskGateSDK.shared.cancelTask()
                isPresented = false
            }
        }
        .padding()
    }
}
```

### UIKit Example

```swift
import UIKit
import TaskGateSDK

class TaskViewController: UIViewController {

    var taskInfo: TaskGateSDK.TaskInfo?

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()

        TaskGateSDK.shared.onTaskReceived = { [weak self] taskInfo in
            self?.taskInfo = taskInfo

            // Signal ready
            TaskGateSDK.shared.notifyReady()

            // Update UI
            self?.displayTask(taskInfo)
        }
    }

    func displayTask(_ taskInfo: TaskGateSDK.TaskInfo) {
        // Update UI based on task
        titleLabel.text = "Complete Task"
        taskLabel.text = taskInfo.taskId

        if let appName = taskInfo.appName {
            appLabel.text = "You tried to open: \(appName)"
        }

        // Show task-specific UI
        loadTaskContent(taskInfo.taskId)
    }

    @IBAction func openButtonTapped(_ sender: UIButton) {
        TaskGateSDK.shared.reportCompletion(.open)
        dismiss(animated: true)
    }

    @IBAction func focusButtonTapped(_ sender: UIButton) {
        TaskGateSDK.shared.reportCompletion(.focus)
        dismiss(animated: true)
    }

    @IBAction func cancelButtonTapped(_ sender: UIButton) {
        TaskGateSDK.shared.cancelTask()
        dismiss(animated: true)
    }
}
```

---

## URL Scheme Format

Your app will receive URLs in this format:

```
yourapp://task?task_id=breathing_30s&session_id=abc123&callback=taskgate://partner-complete&app_name=Instagram
```

**Parameters:**

- `task_id` - Identifier for the task to show
- `session_id` - Unique session identifier
- `callback` - URL to notify TaskGate of completion
- `app_name` - Name of the blocked app (optional)
- Additional custom parameters as needed

---

## Testing

### Test URL

You can test your integration with this URL format:

```
yourapp://task?task_id=test&session_id=test123&callback=taskgate://partner-complete
```

**Option 1: Safari**

```
# Open in Safari on simulator/device
open "yourapp://task?task_id=test&session_id=test123&callback=taskgate://partner-complete"
```

**Option 2: Terminal (Simulator)**

```bash
xcrun simctl openurl booted "yourapp://task?task_id=test&session_id=test123&callback=taskgate://partner-complete"
```

**Option 3: Xcode**

1. Product → Scheme → Edit Scheme
2. Run → Arguments
3. Add to "Arguments Passed On Launch"
4. Add launch argument with custom URL

---

## Becoming a Partner

To get your provider ID and register as a TaskGate partner:

1. **Contact us:** partners@taskgate.app
2. **Provide app details:** App name, task types, pricing
3. **Receive credentials:** We'll provide your `providerId`
4. **Test integration:** We'll help you test the full flow
5. **Go live:** Launch to TaskGate users!

---

## Requirements

- **iOS:** 13.0+
- **Swift:** 5.9+
- **Xcode:** 14.0+

---

## Support

- **Documentation:** [Main SDK README](../../../README.md)
- **Email:** partners@taskgate.app
- **Issues:** [GitHub Issues](https://github.com/task-gate/taskgate-sdk-ios/issues)

---

## License

MIT License - See [LICENSE](LICENSE) file for details.

---

## Version

**Current Version:** 1.0.1

**Changelog:**

- 1.0.1 - Initial release
  - Task receiving and handling
  - Ready signal for cold boot
  - Completion reporting
  - URL scheme support

---

**Made with ❤️ for TaskGate Partners**
