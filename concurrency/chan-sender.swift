//
//  chan-sender.swift
//  concurrency
//
//  Created by Guillaume Lessard on 2014-08-23.
//  Copyright (c) 2014 Guillaume Lessard. All rights reserved.
//

/**
  Sender<T> is the sending endpoint for a ChannelType.
*/

extension Sender
{
  /**
    Return a new Sender<T> to act as the sending enpoint for a Chan<T>.

    :param: c A Chan<T> object
    :return:  A Sender<T> object that will send elements to the Chan<T>
  */

  public static func Wrap(c: Chan<T>) -> Sender<T>
  {
    return Sender(c)
  }

  /**
    Return a new Sender<T> to act as the sending enpoint for a ChannelType

    :param: c An object that implements ChannelType
    :return:  A Sender<T> object that will send elements to c
  */

  static func Wrap<C: ChannelType where C.Element == T>(c: C) -> Sender<T>
  {
    if let c = c as? Chan<T>
    {
      return Sender(c)
    }

    return Sender(ChannelTypeAsChan(c))
  }

  /**
    Return a new Sender<T> to stand in for SenderType c.

    If c is a (subclass of) Sender, c will be returned directly.

    If c is any other kind of SenderType, c will be wrapped in a WrappedSender.

    :param: c A SenderType implementor to be wrapped by a Sender object.

    :return:  A Sender object that will pass along the elements to c.
  */

  public static func Wrap<C: SenderType where C.SentElement == T>(c: C) -> Sender<T>
  {
    if let c = c as? Sender<T>
    {
      return c
    }

    return Sender(SenderTypeAsChan(c))
  }
}

public struct Sender<T>: SenderType
{
  private let wrapped: Chan<T>

  public init(_ c: Chan<T>)
  {
    wrapped = c
  }

  // SenderType implementation

  public var isClosed: Bool { return wrapped.isClosed }
  public var isFull:   Bool { return wrapped.isFull }
  public func close()  { wrapped.close() }

  public func send(newElement: T) -> Bool { return wrapped.put(newElement) }
}

/**
  ChannelTypeAsChan<T> disguises any ChannelType as a Chan<T>,
  for use by Sender<T>
*/

private class ChannelTypeAsChan<T, C: ChannelType where C.Element == T>: Chan<T>
{
  private var wrapped: C

  init(_ c: C)
  {
    wrapped = c
  }

  override var isClosed: Bool { return wrapped.isClosed }
  override var isFull:   Bool { return wrapped.isFull }
  override func close()  { wrapped.close() }

  override func put(newElement: T) -> Bool { return wrapped.put(newElement) }
}

/**
  SenderTypeAsChan<T,C> disguises any SenderType as a Chan<T>,
  for use by Sender<T>
*/

private class SenderTypeAsChan<T, C: SenderType where C.SentElement == T>: Chan<T>
{
  private var wrapped: C

  init(_ sender: C)
  {
    wrapped = sender
  }

  override var isClosed: Bool { return wrapped.isClosed }
  override var isFull:   Bool { return wrapped.isFull }
  override func close()  { wrapped.close() }

  override func put(newElement: T) -> Bool { return wrapped.send(newElement) }
}
