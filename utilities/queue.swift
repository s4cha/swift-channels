//
//  queue.swift
//  concurrency
//
//  Created by Guillaume Lessard on 2014-08-16.
//  Copyright (c) 2014 Guillaume Lessard. All rights reserved.
//

/**
  A simple queue, implemented as a linked list.
*/

public class Queue<T>: SequenceType, GeneratorType
{
  final private var head: Node<T>?
  final private var tail: Node<T>!

  final private var size: Int

  final private var mutex = dispatch_semaphore_create(1)!

  public init()
  {
    head = nil
    tail = nil
    size = 0
  }

  public init(newElement: T)
  {
    let newNode = Node<T>(newElement)
    head = newNode
    tail = newNode
    size = 1
  }

  final public var isEmpty: Bool { return size == 0 }

  final public var count: Int { return size }

  public func realCount() -> Int
  {
    var i = 0
    var node = head
    while let n = node
    { // Iterate along the linked nodes while counting
      node = n.next
      i++
    }
    assert(i == size, "Queue might have lost data")

    return Int(i)
  }

  public func enqueue(newElement: T)
  {
    let newNode = Node<T>(newElement)

    dispatch_semaphore_wait(mutex, DISPATCH_TIME_FOREVER)

    if size <= 0
    {
      head = newNode
      tail = newNode
      size = 1
      dispatch_semaphore_signal(mutex)
      return
    }

    tail.next = newNode
    tail = newNode
    size += 1
    dispatch_semaphore_signal(mutex)
  }

  public func dequeue() -> T?
  {
    dispatch_semaphore_wait(mutex, DISPATCH_TIME_FOREVER)

    if size > 0
    {
      let oldhead = head!

      // Promote the 2nd item to 1st
      head = oldhead.next

      size -= 1

      // Logical housekeeping
      if size == 0 { tail = nil }

      dispatch_semaphore_signal(mutex)

      return oldhead.element
    }

    // queue is empty
    dispatch_semaphore_signal(mutex)
    return nil
  }

  // Implementation of GeneratorType

  public func next() -> T?
  {
    return dequeue()
  }

  // Implementation of SequenceType

  public func generate() -> Self
  {
    return self
  }
}

/**
  A simple Node for the Queue implemented above.
  Clearly an implementation detail.
*/

private class Node<T>
{
  let element: T
  var next: Node<T>? = nil

  /**
    The purpose of a new Node<T> is to become last in a Queue<T>.
  */

  init(_ e: T)
  {
    element = e
  }
}
