enum InfiniteRangeSequence<Element> where Element: Strideable, Element.Stride: SignedInteger {

  static func sequenceForward(from: Element, in range: Range<Element>) -> UnfoldFirstSequence<Element> {
    return sequence(first: from) { current in
      if current == range.upperBound.advanced(by: -1) {
        return range.lowerBound
      }
      return current.advanced(by: 1)
    }
  }

  static func sequenceBackward(from: Element, in range: Range<Element>) -> UnfoldFirstSequence<Element> {
    return sequence(first: from) { current in
      if current == range.lowerBound {
        return range.upperBound.advanced(by: -1)
      }
      return current.advanced(by: -1)
    }
  }

}

extension InfiniteRangeSequence where Element == Int {

  static func zero() -> UnfoldFirstSequence<Element> {
    return sequence(first: 0) { $0 }
  }

}
