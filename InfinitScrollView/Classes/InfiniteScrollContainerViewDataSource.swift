import Combine

public final class InfiniteScrollContainerViewDataSource<ContentView: ContentViewProtocol, ImageData>:
  InfiniteScrollContainerViewDataSourceProtocol {

  public typealias ContentUpdateHandler = (ContentView, ImageData, Int) -> Void

  // MARK: Properties

  public var scrollEnabled: Bool {
    self.imageData.count > 1
  }

  public var currentContentIndex: AnyPublisher<Int, Never> {
    self.currentIndex
      .removeDuplicates()
      .compactMap({ $0 })
      .eraseToAnyPublisher()
  }

  public var didTapContentAtIndex: AnyPublisher<ImageViewTappedData<ImageData>, Never> {
    self.didTapContentAtIndexSubject
      .compactMap { [weak self] index in
        guard let self = self else { return nil }
        return .init(index: index, productImageData: self.imageData)
      }
      .eraseToAnyPublisher()
  }

  private(set) var forwardIterator: UnfoldFirstSequence<Int> = InfiniteRangeSequence.zero()
  private(set) var backwardIterator: UnfoldFirstSequence<Int> = InfiniteRangeSequence.zero()

  private(set) var imageData: [ImageData]
  private(set) var images: [ImageData] = []
  private let currentIndex = CurrentValueSubject<Int?, Never>(nil)

  private let didTapContentAtIndexSubject = PassthroughSubject<Int, Never>()


  let viewBuilder: (Int) -> ContentView
  public let contentViewUpdator: ContentUpdateHandler
  public let mode: InfiniteScrollContainerViewMode
  
  private var cancellables = Set<AnyCancellable>()

  // MARK: Initializers

  public init(
    imageData: [ImageData],
    viewBuilder: @escaping (Int) -> ContentView,
    contentViewUpdator: @escaping ContentUpdateHandler
  ) {
    self.imageData = imageData
    self.viewBuilder = viewBuilder
    self.contentViewUpdator = contentViewUpdator
    self.mode = imageData.count > 1 ? .infiniteScroll : .singleImageNoScrollable

    self.loadPageAt(index: 0)
  }

  // MARK: Methods

  public func convertCacheIndexToImageIndex(cachedViewIndex: Int) -> Int? {
    if cachedViewIndex < 1 {
      var backwardIterator = self.backwardIterator
      return backwardIterator.next()
    } else if cachedViewIndex == 1 {
      return self.currentIndex.value
    } else {
      var forwardIterator = self.forwardIterator
      return forwardIterator.next()
    }
  }

  public func makeContentViews() -> [ContentView] {
    (0 ..< self.mode.cacheSize).map(self.viewBuilder)
  }

  public func cachedImageAtIndex(_ index: Int) -> ImageData {
    return self.images[index]
  }

  public func bindTappedImageAtIndex(signal: AnyPublisher<Int, Never>) {
    signal
      .compactMap { [weak self] cachedViewIndex -> Int? in
        self?.convertCacheIndexToImageIndex(cachedViewIndex: cachedViewIndex)
      }
      .subscribe(self.didTapContentAtIndexSubject)
      .store(in: &cancellables)
  }

  public func moveToNextPage() {
    guard self.mode.hasMultiplePages else { return }

    guard let currentIndex = self.currentIndex.value else {
      return
    }
    self.preloadForward()

    self.currentIndex.send(self.forwardIterator.next() ?? self.imageData.startIndex)

    self.backwardIterator = InfiniteRangeSequence.sequenceBackward(
      from: currentIndex,
      in: self.imageData.indices
    )
  }

  public func moveToPreviousPage() {
    guard self.mode.hasMultiplePages else { return }

    guard let currentIndex = self.currentIndex.value else {
      return
    }
    self.preloadBackward()

    self.currentIndex.send(self.backwardIterator.next() ?? self.imageData.startIndex)

    self.forwardIterator = InfiniteRangeSequence.sequenceForward(
      from: currentIndex,
      in: self.imageData.indices
    )
  }

  public func loadPageAt(index: Int) {
    guard self.imageData.indices.contains(index) else {
      return
    }
    // make a copy of the iterator so the state keeps on its intialing state
    var forwardSequence = InfiniteRangeSequence.sequenceForward(
      from: index,
      in: self.imageData.indices
    )
    // skip the current index
    _ = forwardSequence.next()

    self.forwardIterator = forwardSequence

    // make a copy of the iterator so the state keeps on its intialing state
    var backwardSequence = InfiniteRangeSequence.sequenceBackward(
      from: index,
      in: self.imageData.indices
    )
    // skip the current index
    _ = backwardSequence.next()

    self.backwardIterator = backwardSequence

    let backwardIndex = backwardSequence.next() ?? self.imageData.startIndex
    let forwardIndex = forwardSequence.next() ?? self.imageData.startIndex
    self.images = [
      self.imageData[backwardIndex],
      self.imageData[index],
      self.imageData[forwardIndex]
    ]

    self.currentIndex.send(index)
  }

  private func preloadForward() {
    guard self.mode.hasMultiplePages else { return }

    guard let preloadIndex = Array(self.forwardIterator.prefix(self.mode.cacheSize - 1)).last
          else {
      return
    }
    let imageData: ImageData = self.imageData[preloadIndex]
    self.images.removeFirst()
    self.images.append(imageData)
  }

  private func preloadBackward() {
    guard self.mode.hasMultiplePages else { return }

    guard let preloadIndex = Array(self.backwardIterator.prefix(self.mode.cacheSize - 1)).last
          else {
      return
    }
    let imageData: ImageData = self.imageData[preloadIndex]
    self.images.removeLast()
    self.images.insert(imageData, at: 0)
  }

}
