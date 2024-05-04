import Combine


protocol ContentViewProtocol: UIView {
  var didTap: AnyPublisher<Void, Never> { get }
}

struct ImageViewTappedData<ImageData> {
  let index: Int
  let productImageData: [ImageData]
}

protocol InfiniteScrollContainerViewDataSourceProtocol: AnyObject {

  associatedtype ImageData
  associatedtype ContentView: ContentViewProtocol


  var mode: InfiniteScrollContainerViewMode { get }

  var contentViewUpdator: (ContentView, ImageData, Int) -> Void { get }

  var scrollEnabled: Bool { get }

  var didTapContentAtIndex: AnyPublisher<ImageViewTappedData<ImageData>, Never> { get }

  var currentContentIndex: AnyPublisher<Int, Never> { get }

  func cachedImageAtIndex(_ index: Int) -> ImageData

  func convertCacheIndexToImageIndex(cachedViewIndex: Int) -> Int?

  func moveToNextPage()

  func moveToPreviousPage()

  func loadPageAt(index: Int)

  func makeContentViews() -> [ContentView]

  func bindTappedImageAtIndex(signal: AnyPublisher<Int, Never>)

}
