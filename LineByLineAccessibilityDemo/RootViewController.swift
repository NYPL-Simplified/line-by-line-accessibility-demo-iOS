import UIKit

final class RootViewController: UIViewController {
  
  private let webView = PagedWebView()
  
  override var prefersStatusBarHidden: Bool {
    return true
  }
  
  override func viewDidLoad() {
    self.webView.frame = self.view.bounds
    self.webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    self.view.addSubview(self.webView)
    
    self.loadFirstPage()
  }
  
  private func loadFirstPage() {
    let url = Bundle.main.url(forResource: "click-test", withExtension: "html")
    self.webView.loadUrl(url: url!)
  }
}
