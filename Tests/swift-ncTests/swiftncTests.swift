//
//  swiftncTests.swift
//  swiftncTests
//
//  Created by xpwu on 2022/5/24.
//

import XCTest
@testable import xpwu_nc

fileprivate actor IntActor {
	var times = 0
	
	func plus() {
		times += 1
	}
	
	func value()-> Int {
		return times
	}
}

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
		XCTAssertEqual(UserInfoChanged.self.name, UserInfoChanged.name)
		XCTAssertEqual(UserInfoChanged.self.name
									 , Notification.Name(rawValue: "swiftncTests.UserInfoChanged"))
		XCTAssertNotEqual(UploadProgressChanged.self.name, UserInfoChanged.self.name)
		XCTAssertNotEqual(UploadProgressChanged.self.name, Built.self.name)
	}
	
//	func testO1() {
//		NC.default.addObserver1(self, forEvent: UserInfoChanged.self) { e in
//			let a = e.getIds()
//		}
//	}
	
	func testAdd() async {
		let expectation = self.expectation(description: "testAdd")
		
		var times = IntActor()
		var eventB = IntActor()
		
		await NC.default.add(event: UserInfoChanged.self) { e, removeIt in
			if await times.value() == 3 {
				await removeIt()
			}

			await eventB.plus()
			XCTAssertEqual(e.ids, ["a", "b"])
		}
		
		await NC.default.add(event: Built.self) { e, removeIt in
			XCTAssertFalse(true)
		}
		
		_ = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [times,eventB] timer in
			Task {
				await times.plus()
				if await times.value() <= 3 {
					await NC.default.post(UserInfoChanged.init(["a", "b"]))
					
					let eb = await eventB.value()
					let t = await times.value()
					XCTAssertEqual(eb, t)
					return
				}
				
				await NC.default.post(UserInfoChanged.init(["c", "d"]))
				
				let eb = await eventB.value()
				let t = await times.value()
				XCTAssertNotEqual(eb, t)
				
				if await times.value() == 5 {
					timer.invalidate()
					expectation.fulfill()
				}
			}
		}
		
		await self.fulfillment(of: [expectation], timeout: 10)
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
		
		
		await NC.default.add(event: UserInfoChanged.self) { e, removeIt in
			userInfoChangedBlock3 += 1
			XCTAssertEqual(e.ids, userInfoChangedVar)
			
			if 3 == userInfoChangedBlock3 {
				await removeIt()
			}
		}
		
		await NC.default.add(event: UserInfoChanged.self) { e, _ in
			userInfoChangedBlockEver += 1
			XCTAssertEqual(e.ids, userInfoChangedVar)
		}
		
		var autoRelease: Observer? = Observer()
		
		await NC.default.addObserver(autoRelease!, forEvent: UploadProgressChanged.self) { e in
			uploadProgressChangedBlock += 1
			XCTAssertEqual(e.ids, uploadProgressChangedVar)
		}
		
		let o = Observer()
		
		await NC.default.addObserver(o, forEvent: Built.self) { e in
			buildBlockEver += 1
			XCTAssertEqual(e.ids, buildBlockVar)
		}
		
		let oRemove = Observer()
		
		await NC.default.addObserver(oRemove, forEvent: Built.self) { e in
			buildBlock += 1
			XCTAssertEqual(e.ids, buildBlockVar)
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
