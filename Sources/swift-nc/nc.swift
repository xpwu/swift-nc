//
//  nc.swift
//  swiftnc
//
//  Created by xpwu on 2022/5/24.
//

import Foundation


public protocol NCObserverItem: AnyObject {
	func remove() async
}

fileprivate class ObserverItem<T:EventProtocol> : NCObserverItem {
  unowned var queue: Queue<T>
  var id: UInt64

	init (_ queue: Queue<T>, _ id: UInt64) {
    self.queue = queue
    self.id = id
  }
	
	func remove() async {
		await self.queue.remove(self.id)
	}
}

fileprivate final class Value<T:EventProtocol> {
	weak var observerItem: ObserverItem<T>?
	var block: (_ e: T) async ->Void
	var id: UInt64
	
	init(observer: ObserverItem<T>, block: @escaping (_: T) async -> Void, _ id: UInt64) {
		self.observerItem = observer
		self.block = block
		self.id = id
	}
}

public actor DicActor<KEY: Hashable, VAL> {
	var o:[KEY: VAL] = [:]
	
	func values() -> any Collection<VAL> {
		return o.values
	}
	
	func remove(_ ids: [KEY]) {
		for id in ids {
			o.removeValue(forKey: id)
		}
	}
	
	func add(_ id :KEY, _ value: VAL) {
		o[id] = value
	}
	
	func get(_ id: KEY) -> VAL? {
		return o[id]
	}
	
	func removeAll() -> any Collection<VAL> {
		let v = o.values
		o.removeAll()
		return v
	}
}

fileprivate actor Num {
	var num: UInt64 = 0
	
	func get() -> UInt64 {
		num += 1
		return num
	}
}

fileprivate final class Queue<T:EventProtocol> {
	let dic:DicActor<UInt64, Value<T>> = DicActor()
	let idNum:Num = Num()
	
	// post 执行过程中，某个 block 可能调用 add / remove 方法，
	// 所以，post 需要拿到 [blocks] 后，再执行 block，防止与 add / remove 互锁在 actor 上
	func post(_ e: T) async {
		var needDel: [UInt64] = []
		
		for value in await dic.values() {
			if value.observerItem == nil {
				needDel.append(value.id)
				continue
			}
			
			await value.block(e)
		}
		
		await dic.remove(needDel)
	}
	
	func add(_ block: @escaping (_ e: T) async ->Void) async -> NCObserverItem {
		let id = await idNum.get()
		let obsever = ObserverItem(self, id)
		await dic.add(id, Value(observer: obsever, block: block, id))
		
		return obsever
	}
	
	func remove(_ no: UInt64) async {
		await dic.remove([no])
	}
}

fileprivate typealias AnyQueue = Any

fileprivate actor EventQueue {
	var values:[EventProtocol.Name:AnyQueue] = [:]
	
	func get<T:EventProtocol>(_ id: T.Type) -> Queue<T> {
		guard let ret = values[id.name] else {
			let initVal = Queue<T>()
			values[id.name] = initVal
			return initVal
		}
		
		return ret as! Queue<T>
	}
}

public final class NC: Sendable {
	
	private let events = EventQueue()
	fileprivate let uuid = UUID()
	
	public func addEvent<T:EventProtocol>(_ e: T.Type
																				, _ block: @escaping (_ e: T) async ->Void) async -> NCObserverItem {
		let q = await events.get(e)
		return await q.add(block)
	}
	
	public func post<T:EventProtocol>(_ e: T) async {
		let q = await events.get(type(of: e))
		await q.post(e)
	}
	
}

extension NC: Hashable {
	public static func == (lhs: NC, rhs: NC) -> Bool {
		return lhs.uuid == rhs.uuid
	}
	
	public func hash(into hasher: inout Hasher) {
		hasher.combine(uuid)
	}
}

