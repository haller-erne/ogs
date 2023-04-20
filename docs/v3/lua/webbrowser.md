# Browser

## Overview 

The OGS runtime uses up to 4 web browser (Microsoft WebView2) instances. The instances are:

- `StartView`: Browser on the start screen
- `ProcessView`: Browser on the process screen (only visible, if the `url`-parameter in the job/task is set)
- `SidePanel`: Browser on the slide-in side panel (requires enabling the sidepanel in `station.ini`)
- `InstructionView`: Browser in the instruction view popup (is triggered from LUA, so only visible with custom LUA code)

The OGS infrastructure provides functions to bidirectionally exchange data between the JavaScript code running inside the web browser and the LUA code running inside OGS. There is a LUA function to execute JavaScript code in the webbrowser and a JavaScript bridge, which calls a LUA function (if registered accordingly). To make things a bit easier, starting with OGS V3.0.8510, there is also a JavaScript helper object injected into the page.

To implement this functionality, OGS provides the following:

- For the LUA side: a global `Browser` table with functions to manipulate the browser instances
- For the JavaScript side: 
	- an [injected JavaScript helper object](#injected-javascript-helper-object), which provides easy to use functions to access the Bridge and send a message string
	- the (lowlevel) [JavaScript hostObjects bridge](#javascript-hostobjects-bridge) accessibal through the `hostObjects` interface of the Chromium browser (`window.chrome.webview.hostObjects.sync.<instance>`, with `instance` one of the above)

## Injected JavaScript helper object

**NOTE**: Available starting with OGS V3.0.8510.

OGS injects a JavaScript `OGS` object into the page after the "NavigationComplete" Event of the Edge Browser. This especially makes using the `Bridge` to send messages out to the OGS core easier (see [JavaScript hostObjects bridge](#javascript-hostobjects-bridge) below for details) and also allows overriding some events. The `OGS`-object provides the following members:

- `getBridgeName(): string`: Returns the bridge instance name (which is identical to the browser instance name, e.g. `'StartView'`).
- `SendCmd(cmd: string): boolean`: send the `cmd` string  to the OGS core. The function returns `true`, if the string was sent correctly. If `false` is returned, the command was not sent. This usually happens during and shortly after page load (and even for a small time after DocumentComplete), as the Edge bridge host object needs some time to initialize. Best practice is to embed the `SendCmd()` into a timer started with window.onload() or in the body. An even **better option** is to implement the OGS.onInit() override (see sample below).
- event: `onInit(url: string)`: This function can be implemented on the JavaScript side to get notified when OGS is done loading the webpage (called after the `OnNavigateComplete`-Event of the Edge browser). This can(should) be used to have a reliable event on when the OGS-Communication is available.
- event: `onShow()`: This function can be implemented on the JavaScript side to get notified when the web browser gets visible to the user. This is especially useful for the `SidePanel` view, as the user can open/close the browser view without reloading the page.
- event: `onHide()`: This function can be implemented on the JavaScript side to get notified when the web browser gets visible to the user.


Here is a sample on how to use the `OGS`-JavaScript helper oject to send a "hello"-message after the bridge gets ready:

``` html
<!DOCTYPE html>
<html >
</html>
<body>
<!-- whatever content is in the page -->
</body>

<script>
// Create the OGS object and implement the callbacks/events
OGS = {};		
OGS.onInit = function(url) {
	console.log("OGS.onInit called: ", url, OGS);
	// if we get here, everyhing is initialized, so now send the 'hello' message
	OGS.SendCmd('hello!');
}
OGS.onShow = function OGS_onShow() {
	console.log("OGS.onShow called!");
}
OGS.onHide = function() {
	console.log("OGS.onHide called!");
}
</script>
``` 

An alternative way (without using the OGS object) would be to poll until everything is ready:

``` JavaScript
// Send Hello after the bridge is ready
function SendHello()
	var timer = window.setInterval( () => {
		if (OGS) {	// check, if the global OGS object exists
			if (OGS.SendCmd('Hello')) {
				// successfully send, remove the timer
				clearInterval(timer);
			}
		}
	}, 100);	// execute every 100ms until the bridge is ready
end
window.onload = function() {
	SendHello();
}
```

 
## JavaScript hostObjects bridge

**NOTE**: Starting with OGS V3.0.8510, it is recommended to use the [JavaScript hostObjects bridge](#javascript-hostobjects-bridge) instead. 

To allow interaction between the JavaScript code running in the Browser and the OGS core, OGS registers a [hostObject](https://learn.microsoft.com/en-us/dotnet/api/microsoft.web.webview2.core.corewebview2.addhostobjecttoscript) in the WebView2 browser for the JavaScript side. The registered object is named identically to the browser instance, e.g. `StartView` and implements a single string property `ObjectMessage`.

To send a string to OGS from JavaScript, simply assign a value to the `window.chrome.webview.hostObjects.sync.<instance>.ObjectMessage` property (`instance` is the name of the actual browser instance, e.g. `StartView`, `ProcessView`, ..., see above).

**NOTE**: To use the bridge, one has to use the correct `<instance>`!

#### Sample code

``` javascript
// send a command string to OGS	- from the StartView instance
function sendOgsCommand(cmd)
{
	if (!window.chrome || !window.chrome.webview
	 || !window.chrome.webview.hostObjects
	 || !window.chrome.webview.hostObjects.sync) {
        // WebView2 is not yet fully initialized
		return;     
	}
	let ogs = window.chrome.webview.hostObjects.sync.StartView;
	if (ogs) {
		ogs.ObjectMessage = cmd;	
	}
}
``` 

## Global Browser table

OGS exposes the browser instances through the global `Browser` object. The `Browser` object implements the following functions:

- [Navigate](#navigate): Load a new URL in the web browser
- [ExecJS_nonblocking](#execjs-nonblocking): Run javascript inside the web browser (asynchronously, not returning a value)
- [RegMsgHandler](#reg.msg-handler): Register a LUA callback function to be called when the JavaScript side writes to the object message endpoint.

<!--
The following functions are also available, but are not fully implemented at the moment:
- [ExecJS_sync](#execjs-sync): 
- [ExecJS_async](#execjs-async):
- [Show](#show): 
- [Hide](#hide): 
- [GetState](#getstate): 
-->

### Navigate

The `Browser.Navigate` function starts loading a new URL into the given browser instance.

```LUA
Browser.Navigate(instance, url)
```

#### Parameters

- instance [string]: Web browser instance name (one of 'StartView', 'ProcessView', 'SidePanel', 'InstructionView') 
- url [string]: Url to navigate the browser instance to (in the standard URL format, e.g. file://filename or https://server/page)

#### Sample code
```LUA
-- Navigate the StartView browser to https://www.my-url.com/mypage
Browser.Navigate('StartView', 'https://www.my-url.com/mypage')
```

### Show

The `Browser.Show` function is similar to the `Browser.Navigate` function, but also ensures the webbrowser is actually visible. The actual behaviour depends on the view - e.g. for the `SidePanel` view, the side panel pops out. For the `ProcessView` view, this switches from the image-view to the web view.

```LUA
local oldUrl = Browser.Show(instance, url)
```

#### Parameters

- instance [string]: Web browser instance name (one of 'StartView', 'ProcessView', 'SidePanel', 'InstructionView') 
- url [string]: Url to navigate the browser instance to (in the standard URL format, e.g. file://filename or https://server/page)

#### Return value

The function returns the "current" URL of the webbrowser (the URL before changing to the given one). This can be used to return to the previous URL after hiding the browser.

#### Sample code
```LUA
-- Make the SidePanel visible and navigate the
-- web browser to https://www.my-url.com/mypage
local oldUrl = Browser.Show('SidePanel', 'https://www.my-url.com/mypage')
```

### Hide

The `Browser.Hide` function is complementary to the `Browser.Show` function - it closes the browser view (only relevant for `SidePanel` and `ProcessView`).

```LUA
Browser.Hide(instance)
```

#### Parameters

- instance [string]: Web browser instance name (one of 'StartView', 'ProcessView', 'SidePanel', 'InstructionView') 

#### Sample code
```LUA
-- Hide the SidePanel
Browser.Hide('SidePanel')
```

### RegMsgHandler

The `Browser.RegMsgHandler` function registers or unregisters a LUA function to be called whenever the JavaScript running in the browser writes a message to the hostObject bridge `OGS.ObjectMessage` property.

```LUA
-- Register the callback function
fn, err = Browser.RegMsgHandler(instance, callbackfn)
```

#### Parameters

- instance [string]: Web browser instance name (one of 'StartView', 'ProcessView', 'SidePanel', 'InstructionView') 
- callbackfn [function]: LUA function to be called when the JavaScript code writes a string to the `OGS.ObjectMessage` hostObject. If callbackfn is `nil`, then the current registration is removed. The callback function has the following signature:

        callbackfn(instance, objectMessage)

Where instance [string] is the web browsers instance name (e.g. 'StartView') and objectMessage [string] the text which was written to the `OGS.ObjectMessage` property of the hostObject bridge from the JavaScript side.

#### Return values

If the function was executed successfully, the callbackfn is returned as the first return value. Else nil is returned and the second return value has an error message string (wrong parameters or unknown instance).

#### Sample code
```LUA
local function callbackfn(instance, objectMessage)
    -- do whatever you want to do here if the javascript 
    -- code writes the OGS.ObjectMessage property
end

-- Register a LUA function to be called from the JavaScript side
Browser.RegMsgHandler('StartView', callbackfn)
```

### ExecJS_nonblocking

The `Browser.ExecJS_nonblocking` executes JavaScript code in the web browser instance.

```LUA
Browser.ExecJS_nonblocking(instance, jstext)
```

#### Parameters

- instance [string]: Web browser instance name (one of 'StartView', 'ProcessView', 'SidePanel', 'InstructionView') 
- jstext [string]: JavaScript string to execute in the browser. Note that this must be valid JavaScript code. 

**NOTES**: 

- When passing strings through the function, make sure to propery escape them!
- Best practice is to write a JavaScript function in the web page and only call it through this function.
- You can serialize LUA objects to a JSON string and pass this through the function. The JavaScript side can then easily deserialize it.

#### Sample code
```LUA
-- Build a JavaScript command, call the function "my_function" with
-- some JSON text
local param = '{ "cmd": "showmessage" }'
local command = "my_function("..param..");"
-- Call the JavaScript function in the StartView browser
Browser.ExecJS_nonblocking('StartView', command)
```

