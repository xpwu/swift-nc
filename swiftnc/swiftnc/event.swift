//
//  event.swift
//  swiftnc
//
//  Created by xpwu on 2022/5/24.
//

import Foundation

open class Event<IDType> {
  
  static public var E:Self {
    get {
      return Self.init([])
    }
  }
  
  public typealias Name = Notification.Name
  
  static var name: Name {
    get {
      return Name(rawValue: NSStringFromClass(self))
    }
  }
  
  var name: Name {
    get {
      return Name(rawValue: NSStringFromClass(Self.self))
    }
  }
  
  private var ids:[IDType] = []
  public func getIds()-> [IDType] {
    return self.ids
  }
  
  public required init(_ ids:[IDType]) {
    self.ids = ids
  }
}

public typealias EventStr = Event<String>

public typealias EventInt = Event<Int>

