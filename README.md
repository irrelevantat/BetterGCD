

BetterGCD 🌪 is a highly simplistic Swift wrapper for the [GCD API](https://developer.apple.com/library/ios/documentation/Performance/Reference/GCD_libdispatch_Ref/index.html). While being simplistic, it allows usage of priority queues, timer-like repetition, delays, error catching, block chaining and value passing. 

## How can I use it?

To make an asynchronous call, just use `async`:

```swift
GCD().async { 
    // do something asynchronously on the main queue
}
```

To make an async call after 5 seconds:

```swift
GCD().after(5).async { 
    // do something asynchronously after 5 seconds
    // executed on the main queue
}
```

Each async call has a queue priority, which can be `main`, `low`, `high`. You can also set your own `dispatch_queue_priority_t` and `flags` if you want.

```swift
GCD().low().async {
    // do something asynchronously on the low priority queue
}
```

Async calls can be chained. Lets assume you want to do a long, low priority, task and then update something on the main queue?

```swift
GCD().low().async { 
    // do background task
}.main().async{
    // call on the main queue after first block finished
}
```

Each block can also be repeated, almost like a ⚡️ `NSTimer`:

```swift
GCD().cycle(10).after(5).async {
    // block is called 10 times
    // block is called every 5 seconds after the last block has finished
    // waits 5 seconds before being called the first time
}
```

### Advanced chaining

BetterGCD allows you to create pipes with a generic value. This makes is less strenuous to pass on results from async calls. 

```swift
GCDPipe<Int>().low().async { _ in
    // do something asynchronously on this queue
    return 42
}.main().async{ answer in
    // do something with your answer
    return nil
}
```

### Error handling

What if an error is being thrown while execution? The pipe skips all remaining blocks and calls the catch block, if there is one. If not, the execution will end silently.

```swift
GCD().async { 
    throw Error.Fatal
}.async { 
    // never called
}.catching { error in
    print("Error: \(error) in async block")
}
```

## Installation

BetterGCD is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'BetterGCD', '~>0.1'
```

## License

BetterGCD is released under an MIT license. See [LICENSE](https://github.com/Sebastian-Hojas/BetterGCD/blob/master/LICENSE) for more information.