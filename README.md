## UML拓扑图
![](https://images.gitee.com/uploads/images/2018/1105/154605_9f474926_657827.jpeg)

## 使用方法
1. 目前`HybirdApp`中混合集成了4种前端和iOS端交互的方法,分别适时采用`UIWebView`和`WKWebView`
	- `UIWebView+URL`拦截方式(A方式)
	- `WKWebView+URL`拦截方式(B方式)
	- `UIWebView+JavaScriptCore`(C方式)
	- `WKWebView+MessageHandle`(D方式)

2. 本架构中类的介绍：
	- `HybirdWebView`是主体，用来处理`webview`的工作；
	- `HybirdInteraction`是交互实体，用来处理响应JS的实体交互方法；
	- `HybirdWebVC`是个集成好的壳，用来处理一些细节，`HybirdWebView`和`HybirdInteraction`之间的联合的关系，大体的方式选择和逻辑修改都在`HybirdWebVC`类实现;
	- 使用：相应的业务修改可以在`HybirdWebVC`里实现,如果对`webView`进行业务处理,可以重写（重新集成`HybirdWebView`）或者继承`HybirdWebVC`类扩展。

3. 使用注意：

	- 业务层的交互动作应该在`HybirdInteraction`子类中实现。
	- 采用不同交互方式需要实现不同的交互代理方法
		- 采用A和B方法:
		`- (BOOL)hybirdWebView:(HybirdWebView *)webView didInvacationURL:(NSString *)invacatinActionURL`
		- 采用C方法
		`- (void)hybirdWebViewDidRegisterJSCallAction:(HybirdWebView *)webView`
		- 采用D方法
		`- (void)hybirdWebView:(HybirdWebView *)webView didReceiveJSMessage:(WKScriptMessage *)message`
		`- (NSArray *)hybirdWebViewDidRegisterWKScriptMessageName:(HybirdWebView *)webView`

## Author

LongLJ：xiaolonglj@gmail.com

## License

HybirdAppDemo is available under the MIT license. See the LICENSE file for more info.
