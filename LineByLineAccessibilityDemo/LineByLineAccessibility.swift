import UIKit

class LineByLineAccessibility: NSObject {

  struct Document {
    let pages: [Page]
  }
  
  struct Page {
    let lines: [Line]
  }
  
  struct Line {
    let pageIndex: Int
    let pageRelativeRect: CGRect
    let text: String
  }
  
  static func documentOfJSONObject(_ object: Any) -> Document? {
    guard let documentObject = object as? [String: Any] else { return nil }
    guard let pagesObject = documentObject["pages"] as? [[String: Any]] else { return nil }
    let maybePages: [Page?] = pagesObject.map { pageObject in
      guard let linesObject = pageObject["lines"] as? [[String: Any]] else { return nil }
      let maybeLines: [Line?] = linesObject.map { lineObject in
        guard let pageIndex = lineObject["pageIndex"] as? Int else { return nil }
        guard let pageRelativeRectObject = lineObject["pageRelativeRect"] as? [String: Double] else { return nil }
        guard let x = pageRelativeRectObject["left"] else { return nil }
        guard let y = pageRelativeRectObject["top"] else { return nil }
        guard let width = pageRelativeRectObject["width"] else { return nil }
        guard let height = pageRelativeRectObject["height"] else { return nil }
        let pageRelativeRect = CGRect(x: x, y: y, width: width, height: height)
        guard let text = lineObject["text"] as? String else { return nil }
        return Line(pageIndex: pageIndex, pageRelativeRect: pageRelativeRect, text: text)
      }
      guard let lines = maybeLines as? [Line] else { return nil }
      return Page(lines: lines)
    }
    guard let pages = maybePages as? [Page] else { return nil }
    return Document(pages: pages)
  }
}
