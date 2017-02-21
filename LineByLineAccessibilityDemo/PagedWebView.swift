import UIKit

class PagedWebView: UIWebView, UIWebViewDelegate, UIAccessibilityReadingContent {
  
  struct Line {
    let rect: CGRect
    let text: String
    let page: Int
  }
  
  var lines: [Line]! = nil
  var currentPageIndex = 0
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    self.paginationMode = .leftToRight
    self.scrollView.isPagingEnabled = true
    self.scrollView.bounces = false
    self.isAccessibilityElement = true
    self.accessibilityTraits = UIAccessibilityTraitCausesPageTurn
    self.delegate = self;
    self.scrollView.delegate = self
  }
  
  @available(*, unavailable)
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  func loadUrl(url: URL) {
    self.isUserInteractionEnabled = false
    self.loadRequest(URLRequest(url: url))
  }
  
  func webViewDidFinishLoad(_ webView: UIWebView) {
    let string = self.stringByEvaluatingJavaScript(from: "lines.shift(); JSON.stringify(lines)")!
    let object = try! JSONSerialization.jsonObject(with: string.data(using: String.Encoding.utf8)!,
                                                   options: [.allowFragments])
    
    var mutableLines: [Line] = []
    for lineObject in object as! [AnyObject] {
      let lineDictionary = lineObject as! [String: AnyObject]
      let text = lineDictionary["text"] as! String
      let rectDictionary = lineDictionary["clientRect"] as! [String: NSNumber]
      let rect = CGRect(
        x: CGFloat(rectDictionary["left"]!.floatValue),
        y: CGFloat(rectDictionary["top"]!.floatValue),
        width: CGFloat(rectDictionary["width"]!.floatValue),
        height: CGFloat(rectDictionary["height"]!.floatValue))
      let page = (lineDictionary["page"] as! NSNumber).intValue
      let line = Line(rect: rect, text: text, page: page)
      mutableLines.append(line)
    }
    
    self.lines = mutableLines
    
    self.isUserInteractionEnabled = true
  }
  
  override func accessibilityScroll(_ direction: UIAccessibilityScrollDirection) -> Bool {
    let pageIndexDelta = direction == .next ? 1 : direction == .previous ? -1 : 0
    self.currentPageIndex = self.currentPageIndex + pageIndexDelta
    let rect = CGRect(x: CGFloat(self.currentPageIndex) * self.frame.width,
                      y: 0,
                      width: self.frame.width,
                      height: self.frame.height)
    self.scrollView.scrollRectToVisible(rect, animated: true)
    UIAccessibilityPostNotification(UIAccessibilityPageScrolledNotification, nil)
    
    return true
  }
  
  // Returns the line number that contains the specified point.
  func accessibilityLineNumber(for point: CGPoint) -> Int {
    for (i, line) in self.linesOnCurrentPage().enumerated() {
      if line.rect.contains(point) {
        return i
      }
    }
    
    return NSNotFound
  }
  
  // Returns the text associated with the specified line number.
  func accessibilityContent(forLineNumber i: Int) -> String? {
    if(i < self.linesOnCurrentPage().count) {
      return self.linesOnCurrentPage()[i].text
    } else {
      return nil
    }
  }
  
  // Returns the onscreen frame associated with the specified line number.
  func accessibilityFrame(forLineNumber i: Int) -> CGRect {
    return self.linesOnCurrentPage()[i].rect
  }
  
  // Returns the text displayed on the current page.
  func accessibilityPageContent() -> String? {
    return self.linesOnCurrentPage().map({line in line.text}).joined(separator: " ")
  }
  
  func linesOnCurrentPage() -> [Line] {
    return self.lines.filter {line in
      line.page == Int(self.scrollView.contentOffset.x / self.scrollView.frame.size.width);
    }
  }
  
  override func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
    self.currentPageIndex = Int(self.scrollView.contentOffset.x / self.scrollView.frame.width)
  }
}
