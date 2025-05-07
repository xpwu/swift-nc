//
//  ncobserver.swift
//  xpwu_nc
//
//  Created by xpwu on 2025/4/26.
//


public struct NCObserverKey {
	var name: EventProtocol.Name
	var nc: NC
	
	init(_ name: EventProtocol.Name, _ nc: NC) {
		self.name = name
		self.nc = nc
	}
}

extension NCObserverKey: Hashable {}

public typealias NCEvents = DicActor<NCObserverKey, NCObserverItem>

public protocol NCObserver {
	var events: NCEvents {get}
}

extension NCObserver {
	public func addEvent<T: EventProtocol>(_ e: T.Type, to nc: NC, _ block: @escaping (_ e: T) async ->Void) async {
		let item = await nc.addEvent(e, block)
		await events.add(NCObserverKey(e.name, nc), item)
	}
	
	public func removeEvent<T: EventProtocol>(_ e: T.Type, from nc: NC) async {
		let key = NCObserverKey(e.name, nc)
		guard let item = await events.get(key) else {
			return
		}
		
		await item.remove()
		await events.remove([key])
	}
	
	public func removeAll() async {
		let values = await events.removeAll()
		for value in values {
			await value.remove()
		}
	}
}

