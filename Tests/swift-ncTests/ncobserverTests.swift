//
//  ncobserverTests.swift
//  xpwu_nc
//
//  Created by xpwu on 2025/5/1.
//


import XCTest
@testable import xpwu_nc

class SomeView {
	let events: NCEvents = NCEvents()
}

extension SomeView: NCObserver {
}

class ncobserverTests: XCTestCase {
	
	func testRemove() async {
		let nc1 = NC()
		let nc2 = NC()
		let view = SomeView()
		await view.removeEvent(UserInfoChanged.self, from: nc1)
		await view.removeEvent(UserInfoChanged.self, from: nc1)
		await view.removeEvent(Built.self, from: nc1)
		await view.removeEvent(UserInfoChanged.self, from: nc1)
		
		await view.removeEvent(UserInfoChanged.self, from: nc2)
		await view.removeEvent(UserInfoChanged.self, from: nc2)
		await view.removeEvent(Built.self, from: nc2)
		await view.removeEvent(UserInfoChanged.self, from: nc2)
		
		await view.removeAll()
		
		XCTAssertTrue(true)
	}
	
	func testAdd() async {
		let nc1 = NC()
		let nc2 = NC()
		let view1 = SomeView()
		let view2 = SomeView()
		
		var uccount = 0
		
		// add1
		await view1.addEvent(UserInfoChanged.self, to: nc1) { e in
			uccount += e.ids.count
		}
		// add2
		await view2.addEvent(UserInfoChanged.self, to: nc1) { e in
			uccount += e.ids.count
		}
		
		await nc1.post(UserInfoChanged(["1", "2"]))
		XCTAssertEqual(uccount, 4)
		await nc2.post(UserInfoChanged(["1", "2"]))
		XCTAssertEqual(uccount, 4)
		
		// add3 note that: reduplicate, so add1 invalid
		await view1.addEvent(UserInfoChanged.self, to: nc1) { e in
			uccount += e.ids.count + 1
		}
		await nc1.post(UserInfoChanged(["1", "2", "3"]))
		// 4 + 3(add2) + 4(add3), add1 not work
		XCTAssertEqual(uccount, 11)
		
		// add4
		await view2.addEvent(UserInfoChanged.self, to: nc2) { e in
			uccount += e.ids.count + 2
		}
		
		await nc1.post(UserInfoChanged(["1", "2", "3"]))
		// 11 + 3(add2) + 4(add3)
		XCTAssertEqual(uccount, 18)
		
		await nc2.post(UserInfoChanged(["1", "2", "3"]))
		// 18 + 5(add4)
		XCTAssertEqual(uccount, 23)
		
		await view2.removeEvent(UserInfoChanged.self, from: nc1)
		
		await nc1.post(UserInfoChanged(["1", "2", "3"]))
		// 23 + 4(add3)
		XCTAssertEqual(uccount, 27)
		
		await nc2.post(UserInfoChanged(["1", "2", "3"]))
		// 27 + 5(add4)
		XCTAssertEqual(uccount, 32)
		
		await view1.removeAll()
		await view2.removeAll()
		
		await nc1.post(UserInfoChanged(["1", "2", "3"]))
		XCTAssertEqual(uccount, 32)
		
		await nc2.post(UserInfoChanged(["1", "2", "3"]))
		XCTAssertEqual(uccount, 32)
		
	}
}
