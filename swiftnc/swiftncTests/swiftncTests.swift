//
//  swiftncTests.swift
//  swiftncTests
//
//  Created by xpwu on 2022/5/24.
//

import XCTest
@testable import swiftnc

class swiftncTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
      
    }
	
	func testEvent() throws {
		XCTAssertEqual(UserInfoChanged.E.name, UserInfoChanged.name)
		XCTAssertEqual(UserInfoChanged.E.name
									 , Notification.Name(rawValue: "swiftncTests.UserInfoChanged"))
		XCTAssertNotEqual(UploadProgressChanged.E.name, UserInfoChanged.E.name)
		XCTAssertNotEqual(UploadProgressChanged.E.name, Built.E.name)
	}
	
	func testAdd() async {
		let expectation = self.expectation(description: "testAdd")
		
		var times = 0
		var eventB = 0
		
		NC.default.add(event: UserInfoChanged.E) { e, removeIt in
			if times == 3 {
				removeIt()
			}

			eventB += 1
			XCTAssertEqual(e.getIds(), ["a", "b"])
		}
		
		NC.default.add(event: Built.E) { e, removeIt in
			XCTAssertFalse(true)
		}
		
		_ = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { timer in
			times += 1
			if times <= 3 {
				NC.default.post(UserInfoChanged.init(["a", "b"]))
				
				XCTAssertEqual(eventB, times)
				return
			}
			
			NC.default.post(UserInfoChanged.init(["c", "d"]))
			
			XCTAssertNotEqual(eventB, times)
			
			if times == 5 {
				timer.invalidate()
				expectation.fulfill()
			}
		}
		
		self.wait(for: [expectation], timeout: 10)
	}
	
	func testAll() async {
		let expectation = self.expectation(description: "testAll")
		
		var postTimes = 0
		
		var userInfoChangedBlock3 = 0
		
		let userInfoChangedVar = ["a", "b"]
		
		var userInfoChangedBlockEver = 0
		
		var buildBlockEver = 0
		
		var buildBlock = 0
		
		let buildBlockVar = [12, 45]
		
		var uploadProgressChangedBlock = 0
		
		let uploadProgressChangedVar = ["dkjfd"]
		
		
		NC.default.add(event: UserInfoChanged.E) { e, removeIt in
			userInfoChangedBlock3 += 1
			XCTAssertEqual(e.getIds(), userInfoChangedVar)
			
			if 3 == userInfoChangedBlock3 {
				removeIt()
			}
		}
		
		NC.default.add(event: UserInfoChanged.E) { e, _ in
			userInfoChangedBlockEver += 1
			XCTAssertEqual(e.getIds(), userInfoChangedVar)
		}
		
		var autoRelease: Observer? = Observer()
		
		NC.default.addObserver(autoRelease!, forEvent: UploadProgressChanged.E) { e in
			uploadProgressChangedBlock += 1
			XCTAssertEqual(e.getIds(), uploadProgressChangedVar)
		}
		
		let o = Observer()
		
		NC.default.addObserver(o, forEvent: Built.E) { e in
			buildBlockEver += 1
			XCTAssertEqual(e.getIds(), buildBlockVar)
		}
		
		let oRemove = Observer()
		
		NC.default.addObserver(oRemove, forEvent: Built.E) { e in
			buildBlock += 1
			XCTAssertEqual(e.getIds(), buildBlockVar)
		}
		
		
		
		_ = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { timer in
			postTimes += 1
			
			NC.default.post(Built.init(buildBlockVar))
			NC.default.post(UserInfoChanged.init(userInfoChangedVar))
			NC.default.post(UploadProgressChanged.init(uploadProgressChangedVar))
			
			XCTAssertEqual(buildBlockEver, postTimes)
			XCTAssertEqual(userInfoChangedBlockEver, postTimes)
			
			let userInfoChangedBlock3C = 3
			if postTimes <= userInfoChangedBlock3C {
				XCTAssertEqual(userInfoChangedBlock3, postTimes)
			} else {
				XCTAssertEqual(userInfoChangedBlock3, userInfoChangedBlock3C)
			}
			
			let autoReleaseC = 7
			if postTimes == autoReleaseC {
				autoRelease = nil
			}
			if postTimes <= autoReleaseC {
				XCTAssertEqual(uploadProgressChangedBlock, postTimes)
			} else {
				XCTAssertEqual(uploadProgressChangedBlock, autoReleaseC)
			}
			
			let removeC = 9
			if postTimes == removeC {
				NC.default.removeObserver(oRemove)
			}
			if postTimes <= removeC {
				XCTAssertEqual(buildBlock, postTimes)
			} else {
				XCTAssertEqual(buildBlock, removeC)
			}
			
			
			if postTimes == 13 {
				timer.invalidate()
				expectation.fulfill()
			}
		}
		
		self.wait(for: [expectation], timeout: 10)
	}

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
