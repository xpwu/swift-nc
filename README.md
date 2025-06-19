# swiftnc
支持 swift 语言的通知中心，支持 async 调用，支持 Sendable 协议，并发安全

## 0、代码库的引用
使用 SwiftPM 引用此 github 库即可

## 1、event
* 满足 EventProtocol 协议的即可成为 Event，一个类即代表一个事件。已提供携带 String/Int 类型参数的 base class，定一个继承类即可定义一个新的事件
	```swift
  class UploadProgressChanged: EventStr {}
  class UserInfoChanged: EventStr {}
  class Built: EventInt {}
  ```
  
* 也可以直接实现 EventProtocol 协议定义新的事件

## 2、nc
* 添加事件   
  ```swift
  let nc = NC()
  
  let item = await nc.addEvent(UserInfoChanged.self) { e in
			// user code
		}
  ```
  
* post 事件
  ```swift
  await nc.post(UserInfoChanged.init(["a", "b"]))
  ```
  
* 删除事件
  ```swift
  item.remove()
  ```

#### 注：
addEvent 返回的 NCObserverItem 需要调用方保存管理，
NC 不会持有 NCObserverItem

## 3、observer
为方便管理多个 NCObserverItem，可以使用扩展 NCObserver 协议来实现，比如需要扩展 SomeView 为 NCObserver
  ```swift
  class SomeView {
    let events: NCEvents = NCEvents()
  }

  extension SomeView: NCObserver {
  }
  ```

则，SomeView 就扩展了如下三个方法
  ```swift
  addEvent(to)
  removeEvent(from)
  removeAll()
  ```

## 4、内存管理
  ```
   //  ~~~~> hold weakly
   //  ----> hold strongly 
  
   NC ~~~~> Item ----> block
  ```
* 返回的 Item 需要由调用层管理。
* block 中如果需要用到 Item 的管理者对象(包括 extension NCObserver 的对象) 或者 Item 自身，
都建议使用 weak 得捕获方式，防止循环引用。
* 调用 item.remove()、observer.removeEvent(from) 或者 observer.removeAll() 都将切断 Item 对 block 的持有。
* 如果 Item 被释放，NC 会自动 remove 此 Item 对应的事件，但是为了防止 block 中引起的循环引用，
所有的 Item 都建议通过 item.remove()、observer.removeEvent(from) 或者 observer.removeAll() 手动删除
