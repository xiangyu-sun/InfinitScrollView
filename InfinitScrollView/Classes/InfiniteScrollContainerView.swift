import UIKit
import Combine

private enum Constants {
  static let iconTappableSize = CGSize(width: 48, height: 48)
  static let movingForwardThreshhold = 1.5
  static let movingBackwardThreshhold = 0.5
}

final class InfiniteScrollContainerView<DataSource: InfiniteScrollContainerViewDataSourceProtocol>: UIView, UIScrollViewDelegate {

  struct Configuration {
    let shouldHideForwardAndBackwardButton: Bool
    let forwardImage: UIImage
    let backwardImage: UIImage
  }

  let dataSource: DataSource
  let configuration: Configuration

  // MARK: Private Properties

  private let scrollView = UIScrollView()
  private let imageViews: [DataSource.ContentView]
  private let moveBackwardButton: UIButton = .init(type: .custom)
  private let moveForwardButton: UIButton = .init(type: .custom)

  // MARK: Initializers

  init(dataSource: DataSource, configuration: Configuration) {
    self.dataSource = dataSource
    self.configuration = configuration

    self.imageViews = dataSource.makeContentViews()

    super.init(frame: .zero)

    self.addSubview(self.scrollView)
    
    self.addConstraints([
      self.scrollView.topAnchor.constraint(equalTo: self.topAnchor),
      self.scrollView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
      self.scrollView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
      self.scrollView.trailingAnchor.constraint(equalTo: self.trailingAnchor)
    ])

    self.imageViews.forEach { imageView in
      self.scrollView.addSubview(imageView)
    }

    self.addSubview(self.moveForwardButton)
    self.addSubview(self.moveBackwardButton)

    self.scrollView.showsHorizontalScrollIndicator = false
    self.scrollView.showsVerticalScrollIndicator = false
    self.scrollView.isScrollEnabled = self.dataSource.scrollEnabled
    self.scrollView.isPagingEnabled = true
    self.scrollView.delegate = self

    self.moveForwardButton.setImage(configuration.forwardImage, for: .normal)
    self.moveBackwardButton.setImage(configuration.backwardImage, for: .normal)

    self.moveForwardButton.addTarget(self, action: #selector(self.scrollToNextPage), for: .touchUpInside)
    self.moveBackwardButton.addTarget(self, action: #selector(self.scrollToPreviousPage), for: .touchUpInside)
    let shouldHideButton = self.configuration.shouldHideForwardAndBackwardButton || !self.dataSource.scrollEnabled
    self.moveForwardButton.isHidden = shouldHideButton
    self.moveBackwardButton.isHidden = shouldHideButton
 

    
    self.addConstraints([
      self.moveForwardButton.centerYAnchor.constraint(equalTo: self.centerYAnchor),
      self.moveForwardButton.trailingAnchor.constraint(equalTo: self.trailingAnchor),
      self.moveForwardButton.widthAnchor.constraint(equalToConstant: Constants.iconTappableSize.width),
      self.moveForwardButton.heightAnchor.constraint(equalToConstant: Constants.iconTappableSize.height)
    ])

    self.addConstraints([
      self.moveBackwardButton.centerYAnchor.constraint(equalTo: self.centerYAnchor),
      self.moveBackwardButton.leadingAnchor.constraint(equalTo: self.leadingAnchor),
      self.moveForwardButton.widthAnchor.constraint(equalToConstant: Constants.iconTappableSize.width),
      self.moveBackwardButton.heightAnchor.constraint(equalToConstant: Constants.iconTappableSize.height)
    ])

    self.setUpBinding()
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    self.layoutImages()

    if self.dataSource.mode.hasMultiplePages {
      self.scrollView.setContentOffset(CGPoint(x: self.scrollView.frame.width, y: 0), animated: false)
    }
  }

  private func setUpBinding() {
 
    self.imageViews.enumerated().forEach { index, view in
      view.isUserInteractionEnabled = true
    
      self.dataSource.bindTappedImageAtIndex(signal: view.didTap
        .map{ index }.eraseToAnyPublisher())
    }
  }

  @objc
  func scrollToNextPage() {
    self.loadImageForwardsAndMoveViewPortBackwards()
    self.scrollTo(horizontalPage: 1, animated: true)
  }

  @objc
  func scrollToPreviousPage() {
    self.loadImageBackwardsAndMoveViewPortForwards()
    self.scrollTo(horizontalPage: 1, animated: true)
  }

  func scrollToPage(atIndex: Int) {
    self.dataSource.loadPageAt(index: atIndex)
    self.layoutImages()
  }

}

// MARK: - subview rearrangement and offset updating

private extension InfiniteScrollContainerView {

  func updateScrollViewOffset(scrollView: UIScrollView, offset: CGPoint) {
    guard scrollView.isDragging else {
      return
    }

    let offsetX = offset.x

    if offsetX > scrollView.frame.size.width * Constants.movingForwardThreshhold {
      self.loadImageForwardsAndMoveViewPortBackwards()
    }

    if offsetX < scrollView.frame.size.width * Constants.movingBackwardThreshhold {
      self.loadImageBackwardsAndMoveViewPortForwards()
    }
  }

  func loadImageForwardsAndMoveViewPortBackwards() {
    self.dataSource.moveToNextPage()
    self.layoutImages()

    self.scrollView.contentOffset.x -= self.scrollView.frame.size.width
  }

  func loadImageBackwardsAndMoveViewPortForwards() {
    self.dataSource.moveToPreviousPage()
    self.layoutImages()

    self.scrollView.contentOffset.x += self.scrollView.frame.size.width
  }

  func scrollTo(horizontalPage: Int, animated: Bool) {
    var frame: CGRect = self.scrollView.frame
    frame.origin.x = frame.size.width * CGFloat(horizontalPage)

    self.scrollView.scrollRectToVisible(frame, animated: animated)
  }

  func layoutImages() {
    let width = self.scrollView.frame.size.width
    let height = self.scrollView.frame.size.height

    let expetctedContextSzie = CGSize(width: CGFloat(self.imageViews.count) * width, height: height)

    // key to avoid layout hitch is to avoid reset its content size even they are the same
    if self.scrollView.contentSize != expetctedContextSzie {
      self.scrollView.contentSize = expetctedContextSzie
    }

    self.imageViews.enumerated().forEach { (index: Int, contentView: DataSource.ContentView) in

      contentView.frame = CGRect(
        x: width * CGFloat(index),
        y: 0,
        width: width,
        height: height
      )
      let imageData = self.dataSource.cachedImageAtIndex(index)
      guard let originImageIndex = self.dataSource.convertCacheIndexToImageIndex(cachedViewIndex: index) else {
        return
      }

      self.dataSource.contentViewUpdator(contentView, imageData, originImageIndex)
    }
  }
  
  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    updateScrollViewOffset(scrollView: scrollView, offset: scrollView.contentOffset)
  }
}
