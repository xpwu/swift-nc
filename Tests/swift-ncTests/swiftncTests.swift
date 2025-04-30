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
									 , Notification.Name(rawValue: "xpwu_ncTests.UserInfoChanged"))
		XCTAssertNotEqual(UploadProgressChanged.self.name, UserInfoChanged.self.name)
		XCTAssertNotEqual(UploadProgressChanged.self.name, Built.self.name)
	}

	
	func testAdd() async {
		
		let times = IntActor()
		let eventB = IntActor()
		
		let nc = NC()
		
		var item: NCObserverItem? = nil
		item = await nc.addEvent(UserInfoChanged.self) { e in
			if await times.value() == 3 {
				await item?.remove()
			}

			await eventB.plus()
			XCTAssertEqual(e.ids, ["a", "b"])
		}
		
		_ = await nc.addEvent(Built.self) { e in
			XCTAssertFalse(true)
		}
		
		while await times.value() < 5 {
			let t = Task { [eventB, times] in
				await times.plus()
				if await times.value() <= 3 {
					await nc.post(UserInfoChanged.init(["a", "b"]))
					
					let eb = await eventB.value()
					let t = await times.value()
					XCTAssertEqual(eb, t)
					return
				}
				
				await nc.post(UserInfoChanged.init(["c", "d"]))
				
				let eb = await eventB.value()
				let t = await times.value()
				XCTAssertNotEqual(eb, t)
				
			}
			
			await t.value
		}
	}
	
	func testAll() async {
//		let expectation = self.expectation(description: "testAll")
		
		let postTimes = IntActor()
		
		let userInfoChangedBlock3 = IntActor()
		
		let userInfoChangedVar = ["a", "b"]
		
		let userInfoChangedBlockEver = IntActor()
		
		let buildBlockEver = IntActor()
		
		let buildBlock = IntActor()
		
		let buildBlockVar = [12, 45]
		
		let uploadProgressChangedBlock = IntActor()
		
		let uploadProgressChangedVar = ["dkjfd"]
		
		let nc = NC()
		
		
		var item1: NCObserverItem? = nil
		item1 = await nc.addEvent(UserInfoChanged.self) { e in
			await userInfoChangedBlock3.plus()
			XCTAssertEqual(e.ids, userInfoChangedVar)
			
			if await userInfoChangedBlock3.value() == 3 {
				await item1?.remove()
			}
		}
		
		let item2 = await nc.addEvent(UserInfoChanged.self) { e in
			await	userInfoChangedBlockEver.plus()
			XCTAssertEqual(e.ids, userInfoChangedVar)
		}
		
		var autoRelease: NCObserverItem? = await nc.addEvent(UploadProgressChanged.self) { e in
			await uploadProgressChangedBlock.plus()
			XCTAssertEqual(e.ids, uploadProgressChangedVar)
		}
		
		let o = await nc.addEvent(Built.self) { e in
			await buildBlockEver.plus()
			XCTAssertEqual(e.ids, buildBlockVar)
		}
		
		let oRemove = await nc.addEvent(Built.self) { e in
			await buildBlock.plus()
			XCTAssertEqual(e.ids, buildBlockVar)
		}
		
		while await postTimes.value() < 13 {
			let t = Task {
				await postTimes.plus()
				
				await nc.post(Built.init(buildBlockVar))
				await nc.post(UserInfoChanged.init(userInfoChangedVar))
				await nc.post(UploadProgressChanged.init(uploadProgressChangedVar))
				
				var v1 = await buildBlockEver.value()
				let pt = await postTimes.value()
				XCTAssertEqual(v1, pt)
				v1 = await userInfoChangedBlockEver.value()
				XCTAssertEqual(v1, pt)
				
				let userInfoChangedBlock3C = 3
				v1 = await userInfoChangedBlock3.value()
				if pt <= userInfoChangedBlock3C {
					XCTAssertEqual(v1, pt)
				} else {
					XCTAssertEqual(v1, userInfoChangedBlock3C)
				}
				
				let autoReleaseC = 7
				if pt == autoReleaseC {
					autoRelease = nil
				}
				v1 = await uploadProgressChangedBlock.value()
				if pt <= autoReleaseC {
					XCTAssertEqual(v1, pt)
				} else {
					XCTAssertEqual(v1, autoReleaseC)
				}
				
				let removeC = 9
				if pt == removeC {
					await oRemove.remove()
				}
				v1 = await buildBlock.value()
				if pt <= removeC {
					XCTAssertEqual(v1, pt)
				} else {
					XCTAssertEqual(v1, removeC)
				}
			}
			
			await t.value
		}
	}

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
