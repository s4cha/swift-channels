//
//  select-types.swift
//  concurrency
//
//  Created by Guillaume Lessard on 2014-08-28.
//  Copyright (c) 2014 Guillaume Lessard. All rights reserved.
//

import Dispatch

/**
  What a type needs to be usable in the Select() function.
*/

// MARK: Selectable

public protocol Selectable: class
{
  /**
    `select_chan()` registers its notification semaphore by calling an implementation's selectNotify() method.

    A `Selectable` can attempt to send data back to select_chan() by first changing the `ChannelSemaphore`'s
    state via its `setState()` method. If that succeeds (by returning `true`) the `ChannelSemaphore`'s
    `selection` property can be set to the `Selection` received as a parameter, which identifies
    the current object to the `select_chan()` function. After setting the `selection`, the `Selectable` should
    `ChannelSemaphore.signal()` method and return.
  
    Failure to change the state should be followed by an immediate return, since `select_chan()` needs to take
    action -- and it is running in the same thread as this call. Note that if `setState()` returns `false`,
    it is a clear sign that another thread is likely to change the state of `select`. `select` can only
    be safely changed between a successful call to `setState()` and a subsequent `signal()`.

    ```
      // there is data to transmit back to select_chan()...
      if select.setState(.Select)
      {
        select.selection = selection
        select.signal()
      }
      return
    ```

    - parameter `select`: a `ChannelSemaphore` to signal the `select_chan()` function.
    - parameter `selection`: a `Selection` instance that identifies this object to the `select_chan()` function.
  */

  func selectNotify(_ select: ChannelSemaphore, selection: Selection)

  /**
    If it makes no sense to invoke the `selectNotify()` method at this time, return `false`.
    If every Selectable in the list returns `false`, `select_chan()` will return `nil`.
  */

  var selectable: Bool { get }
}

func ~= <S1: Selectable>(pattern: S1, selection: Selectable) -> Bool
{
  return pattern === selection
}

func ~= <S1: Selectable>(pattern: S1, selection: Selection) -> Bool
{
  return pattern === selection.id
}

// MARK: SelectableChannelType

protocol SelectableChannelType: ChannelType
{
  func selectGet(_ select: ChannelSemaphore, selection: Selection)
  func extract(_ selection: Selection) -> Element?

  func selectPut(_ select: ChannelSemaphore, selection: Selection)
  @discardableResult func insert(_ selection: Selection, newElement: Element) -> Bool
}

// MARK: SelectableReceiverType

public protocol SelectableReceiverType: ReceiverType, Selectable
{
  func extract(_ selection: Selection) -> ReceivedElement?
}

// MARK: SelectableSenderType

public protocol SelectableSenderType: SenderType, Selectable
{
  @discardableResult func insert(_ selection: Selection, newElement: SentElement) -> Bool
}


/**
  Selection is used to communicate references back to the select_chan() function.
*/

public struct Selection
{
  public unowned let id: Selectable
  public let semaphore: ChannelSemaphore?

  public init(id: Selectable, semaphore: ChannelSemaphore)
  {
    self.id = id
    self.semaphore = semaphore
  }

  public init(id: Selectable)
  {
    self.id = id
    semaphore = nil
  }

  public func withSemaphore(_ semaphore: ChannelSemaphore) -> Selection
  {
    return Selection(id: self.id, semaphore: semaphore)
  }
}
