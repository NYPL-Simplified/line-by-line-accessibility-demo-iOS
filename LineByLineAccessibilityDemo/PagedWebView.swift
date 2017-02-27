import UIKit
import WebKit

class PagedWebView: WKWebView, WKNavigationDelegate, UIScrollViewDelegate, UIAccessibilityReadingContent {
  
  private var currentPageIndex = 0
  private var document: LineByLineAccessibility.Document?
  
  init() {
    let configuration = WKWebViewConfiguration()
    configuration.suppressesIncrementalRendering = true
    super.init(frame: CGRect.zero, configuration: configuration)
    self.navigationDelegate = self;
    self.scrollView.delegate = self
    self.scrollView.isPagingEnabled = true
    self.scrollView.bounces = false
    self.isAccessibilityElement = true
    self.accessibilityTraits = UIAccessibilityTraitCausesPageTurn
  }
  
  @available(*, unavailable)
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
    // Waiting here is a hack, but this is just a demo. Normally the app would
    // call `LineByLineAccessibility.processDocument` itself and handle the result
    // asynchronously.
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
      self.evaluateJavaScript("processedDocument") { (object, error) in
        if let object = object {
          self.document = LineByLineAccessibility.documentOfJSONObject(object)
        }
        
        if(self.document == nil) {
          NSLog("Error: Failed to set document")
        }
      }
    }
  }
  
  
  override func accessibilityScroll(_ direction: UIAccessibilityScrollDirection) -> Bool {
    let pageIndexDelta = direction == .next ? 1 : direction == .previous ? -1 : 0
    self.currentPageIndex = self.currentPageIndex + pageIndexDelta
    let point = CGPoint(x: CGFloat(self.currentPageIndex) * self.frame.width, y: 0)
    self.scrollView.setContentOffset(point, animated: true)
    UIAccessibilityPostNotification(UIAccessibilityPageScrolledNotification, nil)
    
    return true
  }
  
  func accessibilityLineNumber(for point: CGPoint) -> Int {
    guard let document = self.document else { return NSNotFound }
    for (i, line) in document.pages[self.currentPageIndex].lines.enumerated() {
      if line.pageRelativeRect.contains(point) {
        return i
      }
    }
    
    return NSNotFound
  }
  
  func accessibilityContent(forLineNumber i: Int) -> String? {
    return self.document?.pages[self.currentPageIndex].lines[i].text
  }
  
  func accessibilityFrame(forLineNumber i: Int) -> CGRect {
    guard let document = self.document else { return CGRect.zero }
    return document.pages[self.currentPageIndex].lines[i].pageRelativeRect
  }
  
  func accessibilityPageContent() -> String? {
    return document?.pages[self.currentPageIndex].lines.map({line in line.text}).joined(separator: " ")
  }
  
  func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
    self.currentPageIndex = Int(self.scrollView.contentOffset.x / self.scrollView.frame.width)
  }
}
