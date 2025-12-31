import Foundation
import UIKit

/// TaskGate Partner SDK for iOS
///
/// Allows partner apps to:
/// - Receive task requests from TaskGate
/// - Signal when app is ready (cold boot complete)
/// - Report task completion status
///
/// Usage:
/// ```swift
/// // Initialize in AppDelegate
/// TaskGateSDK.shared.initialize(providerId: "your_provider_id")
///
/// // Handle incoming URL in SceneDelegate or AppDelegate
/// TaskGateSDK.shared.handleURL(url)
///
/// // When your app is ready to show the task
/// TaskGateSDK.shared.notifyReady()
///
/// // When task is completed
/// TaskGateSDK.shared.reportCompletion(.open)
/// ```
@objc public class TaskGateSDK: NSObject {
    
    /// Shared instance
    @objc public static let shared = TaskGateSDK()
    
    private let taskgateScheme = "taskgate"
    
    private var providerId: String?
    private var currentSessionId: String?
    private var callbackUrl: String?
    private var currentTaskId: String?
    private var pendingTaskInfo: TaskInfo?
    
    /// Task completion status
    @objc public enum CompletionStatus: Int, CustomStringConvertible {
        /// User completed task and wants to open the blocked app
        case open
        /// User completed task but wants to stay focused
        case focus
        /// User cancelled the task
        case cancelled
        
        public var description: String {
            switch self {
            case .open: return "open"
            case .focus: return "focus"
            case .cancelled: return "cancelled"
            }
        }
        
        var stringValue: String { description }
    }
    
    /// Task information received from TaskGate
    @objc public class TaskInfo: NSObject {
        @objc public let taskId: String
        @objc public let sessionId: String
        @objc public let callbackUrl: String
        @objc public let appName: String?
        @objc public let additionalParams: [String: String]
        
        init(taskId: String, sessionId: String, callbackUrl: String, appName: String?, additionalParams: [String: String]) {
            self.taskId = taskId
            self.sessionId = sessionId
            self.callbackUrl = callbackUrl
            self.appName = appName
            self.additionalParams = additionalParams
        }
    }
    
    /// Delegate for TaskGate events
    @objc public protocol TaskGateDelegate: AnyObject {
        /// Called when a task request is received from TaskGate
        func taskGate(_ sdk: TaskGateSDK, didReceiveTask taskInfo: TaskInfo)
        
        /// Called when TaskGate requests a specific task by ID
        @objc optional func taskGate(_ sdk: TaskGateSDK, didRequestTaskId taskId: String, params: [String: String])
    }
    
    /// Delegate for receiving TaskGate events
    @objc public weak var delegate: TaskGateDelegate?
    
    /// Closure-based callback for task received (alternative to delegate)
    public var onTaskReceived: ((TaskInfo) -> Void)?
    
    private override init() {
        super.init()
    }
    
    /// Initialize the SDK
    ///
    /// - Parameter providerId: Your unique provider ID (assigned by TaskGate)
    @objc public func initialize(providerId: String) {
        self.providerId = providerId
        print("[TaskGateSDK] Initialized for provider: \(providerId)")
    }
    
    /// Handle an incoming URL from TaskGate
    ///
    /// Call this in your SceneDelegate's `scene(_:openURLContexts:)` or AppDelegate's `application(_:open:options:)`
    ///
    /// - Parameter url: The incoming URL
    /// - Returns: true if the URL was handled by TaskGate SDK
    @objc @discardableResult
    public func handleURL(_ url: URL) -> Bool {
        // Check if this is a TaskGate request
        // Expected format: https://yourdomain.com/taskgate/start?task_id=xxx&callback_url=xxx&session_id=xxx
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              let path = components.path as String?,
              path.contains("taskgate") else {
            return false
        }
        
        let queryItems = components.queryItems ?? []
        let params = Dictionary(uniqueKeysWithValues: queryItems.compactMap { item -> (String, String)? in
            guard let value = item.value else { return nil }
            return (item.name, value)
        })
        
        guard let taskId = params["task_id"],
              let callbackUrl = params["callback_url"] else {
            print("[TaskGateSDK] Missing required parameters: task_id or callback_url")
            return false
        }
        
        let sessionId = params["session_id"] ?? generateSessionId()
        let appName = params["app_name"]
        
        // Store session info
        self.currentTaskId = taskId
        self.currentSessionId = sessionId
        self.callbackUrl = callbackUrl
        
        print("[TaskGateSDK] [STEP 1] handleURL() - Received deep link: taskId=\(taskId), sessionId=\(sessionId)")
        
        // Collect additional params
        let reservedKeys = Set(["task_id", "callback_url", "session_id", "app_name"])
        let additionalParams = params.filter { !reservedKeys.contains($0.key) }
        
        // Store task info - will be delivered when notifyReady() is called
        let taskInfo = TaskInfo(
            taskId: taskId,
            sessionId: sessionId,
            callbackUrl: callbackUrl,
            appName: appName,
            additionalParams: additionalParams
        )
        
        pendingTaskInfo = taskInfo
        print("[TaskGateSDK] [STEP 2] handleURL() - Task STORED in pendingTaskInfo. NOT delivered yet.")
        print("[TaskGateSDK] [STEP 2] Waiting for notifyReady() to be called...")
        
        return true
    }
    
    /// Notify TaskGate that the app is ready (cold boot complete)
    ///
    /// Call this when your task UI is ready to be displayed.
    ///
    /// This will:
    /// 1. Deliver the pending task info to your delegate/callback via `didReceiveTask`
    /// 2. Signal TaskGate to dismiss the redirect screen
    @objc public func notifyReady() {
        guard let sessionId = currentSessionId else {
            print("[TaskGateSDK] No active session - cannot notify ready")
            return
        }
        
        print("[TaskGateSDK] [STEP 3] notifyReady() called - App says it's ready")
        
        // Deliver pending task to delegate/callback
        if let taskInfo = pendingTaskInfo {
            print("[TaskGateSDK] [STEP 4] NOW delivering task to delegate/callback: taskId=\(taskInfo.taskId)")
            print("[TaskGateSDK] [STEP 4] Calling onTaskReceived / didReceiveTask NOW (after notifyReady)")
            delegate?.taskGate(self, didReceiveTask: taskInfo)
            delegate?.taskGate?(self, didRequestTaskId: taskInfo.taskId, params: taskInfo.additionalParams)
            onTaskReceived?(taskInfo)
            pendingTaskInfo = nil
            print("[TaskGateSDK] [STEP 4] onTaskReceived / didReceiveTask completed")
        } else {
            print("[TaskGateSDK] [STEP 3] No pending task to deliver")
        }
        
        print("[TaskGateSDK] Notifying TaskGate: app ready (session=\(sessionId))")
        
        // Signal TaskGate to dismiss redirect screen
        var components = URLComponents()
        components.scheme = taskgateScheme
        components.host = "partner-ready"
        components.queryItems = [
            URLQueryItem(name: "session_id", value: sessionId),
            URLQueryItem(name: "provider_id", value: providerId)
        ]
        
        if let url = components.url {
            launchURL(url)
        }
    }
    
    /// Report task completion to TaskGate
    ///
    /// - Parameter status: The completion status (open, focus, or cancelled)
    @objc public func reportCompletion(_ status: CompletionStatus) {
        guard let callback = callbackUrl,
              var components = URLComponents(string: callback) else {
            print("[TaskGateSDK] No callback URL - cannot report completion")
            return
        }
        
        print("[TaskGateSDK] Reporting completion: status=\(status.stringValue), session=\(currentSessionId ?? "nil")")
        
        var queryItems = components.queryItems ?? []
        queryItems.append(URLQueryItem(name: "status", value: status.stringValue))
        
        if let providerId = providerId {
            queryItems.append(URLQueryItem(name: "provider_id", value: providerId))
        }
        if let sessionId = currentSessionId {
            queryItems.append(URLQueryItem(name: "session_id", value: sessionId))
        }
        if let taskId = currentTaskId {
            queryItems.append(URLQueryItem(name: "task_id", value: taskId))
        }
        
        components.queryItems = queryItems
        
        if let url = components.url {
            launchURL(url)
        }
        
        // Clear session
        clearSession()
    }
    
    /// Cancel the current task and notify TaskGate
    @objc public func cancelTask() {
        reportCompletion(.cancelled)
    }
    
    /// Get the current session ID if a task is active
    @objc public var currentSession: String? {
        return currentSessionId
    }
    
    /// Get the current task ID if a task is active
    @objc public var currentTask: String? {
        return currentTaskId
    }
    
    /// Check if there's an active task session
    @objc public var hasActiveSession: Bool {
        return currentSessionId != nil
    }
    
    // MARK: - Private Methods
    
    private func launchURL(_ url: URL) {
        DispatchQueue.main.async {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:]) { success in
                    if !success {
                        print("[TaskGateSDK] Failed to open URL: \(url)")
                    }
                }
            } else {
                print("[TaskGateSDK] Cannot open URL: \(url)")
            }
        }
    }
    
    private func clearSession() {
        currentSessionId = nil
        currentTaskId = nil
        callbackUrl = nil
        pendingTaskInfo = nil
    }
    
    private func generateSessionId() -> String {
        return UUID().uuidString.prefix(8).lowercased()
    }
}
