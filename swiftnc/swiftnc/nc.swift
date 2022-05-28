//
//  nc.swift
//  swiftnc
//
//  Created by xpwu on 2022/5/24.
//

import Foundation


//public protocol NCObserver {
//}

fileprivate protocol NCObserver {
  var id: UInt64 { get }
  var eventName: Event.Name { get }
  var bindObject: AnyObject? {get}
}

fileprivate class Observer<T> : NCObserver {
  var eventName: Event.Name
  var block: (_ e: T, _ o: Observer<T>)->Void
  var id: UInt64
  weak var bindObject: AnyObject? = nil

  @objc fileprivate func selector(n: Notification) {
		self.block(n.object as! T, self)
  }

	init (_ name: Event.Name, _ b: @escaping (_ e: T, _ o: Observer<T>)->Void, _ n:UInt64) {
    self.eventName = name
    self.block = b
    self.id = n
  }
}

public class NC {

	public static let `default` = NC(NotificationCenter.default)
  
  private var nc = NotificationCenter()
  
  private var num:UInt64 = 0
  
  private var observers:[UInt64:NCObserver] = [:]
  
	public convenience init() {
		self.init(NotificationCenter())
	}
	
	init(_ nc: NotificationCenter) {
		self.nc = nc
	}
	
	// must call removeIt to remove this event
	public func add<IDType, T:Event<IDType>>(event e: T
							, _ block: @escaping (_ e: T, _ removeIt: ()->Void)->Void) {
		let o = self.addObserverInner(forEvent: e, { [unowned self] e, o in
			block(e) {
				self.removeNCObserver(o)
			}
		})
		
		o.bindObject = o
	}
  
	// auto remove this observer or call removeObserver to remove
	public func addObserver<U: AnyObject, IDType, T:Event<IDType>>(_ observer: U
							, forEvent e: T, _ block: @escaping (_ e: T)->Void) {

    let o = addObserverInner(forEvent: e) { [unowned self] e, o in
      
      if o.bindObject == nil {
				self.removeNCObserver(o)
        return
      }
      
      block(e)
    }
    
    o.bindObject = observer
  }
	
	public func removeObserver<IDType, T:Event<IDType>>(_ observer: AnyObject, forEvent e: T) {
		for (_, o) in self.observers {
			guard let bindO = o.bindObject else {
				continue
			}
			if bindO === observer && o.eventName == e.name {
				removeNCObserver(o)
			}
		}
	}
	
	public func removeObserver(_ observer: AnyObject) {
		for (_, o) in self.observers {
			guard let bindO = o.bindObject else {
				continue
			}
			if bindO === observer {
				removeNCObserver(o)
			}
		}
	}
	
	public func post<IDType, T:Event<IDType>>(_ e: T) {
		nc.post(name: e.name, object: e, userInfo: nil)
	}
	
	private func addObserverInner<IDType, T:Event<IDType>>(forEvent e: T
							, _ block: @escaping (_ e: T, _ o: Observer<T>)->Void) -> Observer<T> {

		num += 1
		let o = Observer.init(e.name, block, num)
		
		observers[num] = o
		
		nc.addObserver(o, selector: #selector(o.selector), name: e.name, object: nil)
		
		return o
	}
	
	
	private func removeNCObserver(_ observer: NCObserver) {
		nc.removeObserver(observer, name: observer.eventName, object: nil)
		observers.removeValue(forKey: observer.id)
	}
	
}

