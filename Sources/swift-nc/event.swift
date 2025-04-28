//
//  event.swift
//  swiftnc
//
//  Created by xpwu on 2022/5/24.
//

import Foundation

public protocol EventProtocol: AnyObject {
}

internal extension EventProtocol {
	typealias Name = Notification.Name
	
	static var name: Name {
		get {
			return Name(rawValue: NSStringFromClass(self))
		}
	}

}

open class Event<IDType> {

  public let ids:[IDType]
  
  public required init(_ ids:[IDType]) {
    self.ids = ids
  }
}

extension Event: EventProtocol {}

public typealias EventStr = Event<String>

public typealias EventInt = Event<Int>

