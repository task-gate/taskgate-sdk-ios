import XCTest
@testable import TaskGateSDK

final class TaskGateSDKTests: XCTestCase {
    
    func testInitialize() {
        let sdk = TaskGateSDK.shared
        sdk.initialize(providerId: "test_provider")
        
        // SDK should be initialized
        XCTAssertFalse(sdk.hasActiveSession)
    }
    
    func testHandleValidURL() {
        let sdk = TaskGateSDK.shared
        sdk.initialize(providerId: "test_provider")
        
        let url = URL(string: "https://example.com/taskgate/start?task_id=test_task&callback_url=https://callback.com&session_id=abc123")!
        
        let handled = sdk.handleURL(url)
        
        XCTAssertTrue(handled)
        XCTAssertTrue(sdk.hasActiveSession)
        XCTAssertEqual(sdk.currentTask, "test_task")
        XCTAssertEqual(sdk.currentSession, "abc123")
    }
    
    func testHandleInvalidURL() {
        let sdk = TaskGateSDK.shared
        sdk.initialize(providerId: "test_provider")
        
        let url = URL(string: "https://example.com/other/path")!
        
        let handled = sdk.handleURL(url)
        
        XCTAssertFalse(handled)
    }
}
