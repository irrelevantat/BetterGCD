//
//  GCDPipePipe.swift
//  BetterGCDPipe
//
// MIT License
//
// Copyright (c) 2016 Sebastian Hojas
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//

import Foundation

private enum BlockType<T>
{
    case AdvancedExecutionBlock(GCDPipe<T>.AdvancedExecutionBlock)
    case SimpleExecutionBlock(GCDPipe<T>.SimpleExecutionBlock)
    case CatchBlock(GCDPipe<T>.CatchBlock)
}

public class GCD: GCDPipe<Any>{

    public override init()
    {
        super.init()
    }
    private init(previous: GCD)
    {
        super.init(previous: previous)
    }
    
    public func async(execution: SimpleExecutionBlock) -> GCD
    {
        self.execution = BlockType<Any>.SimpleExecutionBlock(execution)
        self.next = GCD(previous: self)
        return self.next as! GCD
    }
    public override func main() -> GCD
    {
        super.main()
        return self
    }
    public override func low(flags: UInt = 0) -> GCD
    {
        super.low(flags)
        return self
    }
    
    public override func high(flags: UInt = 0) -> GCD
    {
        super.high(flags)
        return self
    }
    
    public override func after(time: NSTimeInterval) -> GCD
    {
        super.after(time)
        return self
    }
    public override func cycle(times: Int) -> GCD
    {
        super.cycle(times)
        return self
    }
    public override func priority(priority: dispatch_queue_priority_t, flags: UInt = 0) -> GCD
    {
        super.priority(priority, flags: flags)
        return self
    }
    
    
}


public class GCDPipe<T> {
    
    
   
    public typealias CatchBlock = (ErrorType) -> ()
    public typealias AdvancedExecutionBlock = (T?) throws ->(T?)
    public typealias SimpleExecutionBlock = () throws -> ()
    
    
    
    private var previous: GCDPipe?
    private var next: GCDPipe?
    private var queue: dispatch_queue_t = dispatch_get_main_queue()
    private var after: NSTimeInterval?
    private var repetition: Int = 1
    
    private var execution: BlockType<T>?
    
    //var queue: dispatch_queue_t?
    //var after: NSTimeInterval?
    
    /**
     Initiation of first chain element
     
     - returns: initiated GCDPipe block
     */
    public init()
    {
       self.fire(nil)
    }
    
    
    /**
     Initiates element in execution chain
     
     - parameter previous: Link to previous element of linked list
     
     - returns: initiated GCDPipe block
     */
    private init(previous: GCDPipe<T>)
    {
        self.previous = previous
        // stay on the same queue by default
        self.queue = previous.queue
    }
    
    /**
     Starts the dispatch
     
     - parameter chainValue: value that should be passed on to the block
     */
    private func fire(chainValue: T?) {
        
        let block: dispatch_block_t = {
            
            guard let execution = self.execution else {
                return
            }
            

            self.repetition -= 1
            
            switch execution {
            case .AdvancedExecutionBlock(let _exec):
                do {
                    let retValue = try _exec(chainValue)
                    if self.repetition > 0
                    {
                        self.fire(retValue)
                    }
                    else{
                        self.next?.fire(retValue)
                    }
                    
                }
                catch{
                    self.unwindError(error)
                }
               
                break
            case .SimpleExecutionBlock(let _exec):
                do {
                    try _exec()
                    if self.repetition > 0
                    {
                        self.fire(nil)
                    }
                    else{
                        self.next?.fire(nil)
                    }
                }
                catch{
                    self.unwindError(error)
                }
                break
            case .CatchBlock:
                // no need to call catch block
                return
            }
            
        }
        

        
        guard let after = after else {
            dispatch_async(queue, block)
            return
        }
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(after*Double(NSEC_PER_SEC))), dispatch_get_main_queue(), block)
        
    }
    
    /**
     Unwinds linked list to find catch block and raise error
     
     - parameter error: risen error
     */
    private func unwindError(error: ErrorType)
    {
        
        // find last element
        if let next = next {
            next.unwindError(error)
            return
        }
        
        guard let exec = execution else {
            // Do we ignore error?
            print("Ignored error \(error)")
            return
        }
        
        switch exec {
        case .CatchBlock(let catchBlock):
            // should we do that on the main thread?
            catchBlock(error)
        default:
            print("Should not never happen")
        }
        
    }
    
    
    /**
     Adds a new block to the chains
     
     - parameter execution: block that should be dispatched
     
     - returns: next possible block
     */
    public func async(execution: AdvancedExecutionBlock) -> GCDPipe<T>
    {
        self.execution = BlockType<T>.AdvancedExecutionBlock(execution)
        self.next = GCDPipe<T>(previous: self)
        return self.next!
    }
    
    public func catching(catchBlock: CatchBlock)
    {
        self.execution = BlockType<T>.CatchBlock(catchBlock)
    }
    
    public func main() -> GCDPipe<T>
    {
        queue = dispatch_get_main_queue()
        return self
    }
    public func priority(priority: dispatch_queue_priority_t, flags: UInt = 0) -> GCDPipe<T>
    {
        queue = dispatch_get_global_queue(priority, flags)
        return self
    }
    
    public func low(flags: UInt = 0) -> GCDPipe<T>
    {
        self.priority(DISPATCH_QUEUE_PRIORITY_LOW, flags: flags)
        return self
    }
    
    public func high(flags: UInt = 0) -> GCDPipe<T>
    {
        self.priority(DISPATCH_QUEUE_PRIORITY_HIGH, flags: flags)
        return self
    }
    
    public func after(time: NSTimeInterval) -> GCDPipe<T>
    {
        after = time
        return self
    }
    public func cycle(times: Int) -> GCDPipe<T>
    {
        repetition = times
        return self
    }
    

    
    
    
}

