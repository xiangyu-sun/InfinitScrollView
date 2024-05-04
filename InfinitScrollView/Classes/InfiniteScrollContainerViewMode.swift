enum InfiniteScrollContainerViewMode {
  case singleImageNoScrollable
  case infiniteScroll

  var cacheSize: Int {
    switch self {
    case .singleImageNoScrollable: return 1
    case .infiniteScroll: return 3
    }
  }

  var hasMultiplePages: Bool {
    switch self {
    case .singleImageNoScrollable: return false
    case .infiniteScroll: return true
    }
  }
}
