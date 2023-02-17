# Browser

## Overview 

The OGS runtime uses up to 4 web browser (Microsoft WebView2) instances. The instances are:

- `StartView`: Browser on the start screen
- `ProcessView`: Browser on the process screen (only visible, if the `url`-parameter in the job/task is set)
- `SidePanel`: Browser on the slide-in side panel (requires enabling the sidepanel in `station.ini`)
- `InstructionView`: Browser in the instruction view popup (is triggered from LUA, so only visible with custom LUA code)

The OGS infrastructure provides functions to bidirectionally exchange data between the JavaScript code running inside the web browser and the LUA code running inside OGS. There is a LUA function to execute JavaScript code in the webbrowser and a JavaScript bride, which calls a LUA function (if registered accordingly).

To implement this functionality, OGS provides the following:

- For the JavaScript side: a bridge implementation accessibal through the `hostObjects` interface of the Chromium browser (`window.chrome.webview.hostObjects.sync.OGS`)
- For the LUA side: a global `Browser` table with functions to manipulate the browser instances

## JavaScript hostObjects bridge

OGS registers a [hostObject](https://learn.microsoft.com/en-us/dotnet/api/microsoft.web.webview2.core.corewebview2.addhostobjecttoscript) in the WebView2 browser for the JavaScript side. The registered object is named `OGS` and implements a single string property `ObjectMessage`.

To send a string to OGS from JavaScript, simply assign a value to the `window.chrome.webview.hostObjects.sync.OGS.ObjectMessage` property.

#### Sample code

``` javascript
// send a command string to OGS	
function sendOgsCommand(cmd)
{
	if (!window.chrome || !window.chrome.webview
	 || !window.chrome.webview.hostObjects
	 || !window.chrome.webview.hostObjects.sync) {
        // WebView2 is not yet fully initialized
		return;     
	}
	let ogs = window.chrome.webview.hostObjects.sync.OGS;
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
-- Make the SidePanel visible and navigate the web browser to https://www.my-url.com/mypage
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

