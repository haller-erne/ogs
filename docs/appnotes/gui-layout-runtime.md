# Runtime GUI layout

The following sections describes the screen layout in general, the customization options and the recommended screen resolutions for using the runtime.

## Overview

The OGS runtime (monitor.exe) uses two main screens:

- a start page (displayed while no process is active)
- a process page (displayed while a process is running)

The screen layout is generally optimized for a Full-HD screen (1920x1080) and touch input. Readability and text sizes are optimized for this resolution and aspect ratio (16:9). It also works for 16:10 screens and larger resolutions (expecially if the text scale is set accordingly), but does not work well with lower resolutions.

As the OGS runtime is intended to run in a kiosk-style environment, the OGS display uses a maximized application window and hides the default Windows controls (for minimize, etc.). Also closing the application while a process is running, is prohibited. Only users having the neccessary rights are allowed to abort and close the application.

See the section below for more details about the interface interactions.

### Screen selection

On a multi-monitor system, OGS can be configured to show its screens on a specific monitor. This can be set in the projects `station.ini` file in the `[SCREEN]` section.

The following options are available:

- InitialDisplay: defines the screen number where the main OGS screen should be displayed. If not set, uses the "current" screen to display the main application window.
- InstructionView: defines the screen number where the instruction or projection view should be displayed (mainly used for projecting on a secondary screen). If not given, defaults to the same display, the main application runs on (see `InitialDisplay` above).
- IgnoreWarning: The OGS runtime checks the display resolution and scale during start of the application for the recommended values. If not, a popup is shown to indicate possible display issues and provide configuration hints. To skip this warning, set this parameter to a non-zero value (by default the warning is enabled).
- InitialPosition: This is similar to the `InitialDisplay` parameter and allows positioning the main application window at a specific screen position. Compared to the `InitialDisplay`, it allows to specify exact screen pixel coordinates for the main window, so the main window can be set to e.g. occupy only parts of a screen. The values given should be a comma seperated string in the form x0,y0,x1,y1 with (x0/y0) the top left and (x1/y1) the bottom right coordinates of the main window. If set, this overrides and `InitialDisplay` settings.

### Screen resolution konfiguration

For an optimized experience, the virtual resolution of the application should be 1920x1080 or 1920x1200 pixels after applying the windows display text scaling (`Windows Settings --> Display --> Scaling and Layout --> Scale`).

If e.g. running on a 3K 16:9 screen (2880x1620 pixel), it is recommended to set the display text scale to 150%. This will then map to 1920x1080 pixel virtual (scaled) display size - which is a perfect setting for OGS.

## Start page

### Layout

The layout of the start page is as follows:

![text](startpage.drawio.svg)

The layout uses a fixed height for the top bar (for the logos) and the bottom bar (status bar). Also the width of the barcode entry fields and the project startpage logo is fixed. All other panes will adjust dynamically to changed display sizes.

### Logos

The logos are configurable as follows:

- Software developer logo: The default size is 1328x132 pixels (for 1920 screen with, top-left aligned if smaller: not scaled). If the display text scale is not 100%, then the logo file should be scaled accordingly. The logo is read in the following priority:

    - Read from the (*.png) file set in the projects `station.ini` (in the `[GENERAL]` section, parameter `SoftwareDeveloperLogo=` - note that the path is relative to the OGS installation folder)
    - Read from `monitor.png` (if not set in the project file) 
    - Uses the default logo from the installed `monitor.exe`

- Project startpage logo: The logo is 592x143 pixels and is read from the file defined in the `current_project.logo_file` in the projects `config.lua` file (as a `*.png` or `*.gif` file). The logo is automatically scaled to fill the available space. A `*.gif` file can also be used for an animated logo (if an animated gif file is provided).

### Billboard

The main element in the start page is the start page web view. 
The web view shows a custom web page served through the [OGS integrated webserver](../v3/lua/webserver.md) but can also show any other web page.

The url for the webpage is defined in the `current_project.billboard` value in the projects `config.lua` file. If the value is a full URL (including the protocol prefix), then the URL is used verbatim. If only a file name is given and the [OGS integrated webserver](../v3/lua/webserver.md) is enabled, the file is served from the default webroot.

### Appbar and Sidepanel

As the application is running in kiosk mode (covering the full screen and hiding the default Windows UI elements), interaction is done through the slide-in appbar or the slide-in sidepanel (touch friendly).

- Appbar: The appbar is shown by right clicking the project startpage logo (at top-right). It can also be shown by hitting the `<ESC>` key (if a keyboard is attached). The appbar shows some buttons, especially the close button to close the application.

- Sidepanel: If enabled, the sidepanel opens by double-clicking the project startpage logo (at top-right). It can also be shown by the hotkey key (defined in `station.ini`). The sidepanel shows some buttons in the header row, especially to hide the panel and to minimize the application.

## Process page

### Layout

The layout of the process page is as follows:

![text](processpage.drawio.svg)

The layout uses a fixed height for the process page logo and the bottom bar (status bar). Also the width of the process list and buttons (and the process page logo) is fixed. All other panes will adjust dynamically to changed display sizes.

### Logo

The project process page logo is 710x143 pixels and defaults to the same logo as the start page logo. It is autoscaled to fill the size (so if using the same logo as on the startpage will have black borders on the left and right side due to the 710 vs. 592 pixel with). 

A seperate logo for the process view can be read from the file defined in the `current_project.process_view_logo` in the projects `config.lua` file (as a png file).

### Sidepanel

As the application is running in kiosk mode (covering the full screen and hiding the default Windows UI elements), interaction is done through the slide-in sidepanel (touch friendly). Generally, if the process page is visible (i.e. a process is running), the application cannot be stopped/closed. To close the application, one has to stop the process first and return to the start screen (which only a user who has the neccessary right can do). If a process is running, the user has to hit the `stop` button, then the `done` button (both requires rights), then the appbar can be used to close the application (see above).

If the side panel is enabled, the sidepanel can also be opened on the process page by double-clicking the project process page logo (at top-right). It can also be shown by the hotkey key (defined in `station.ini`). The sidepanel shows some buttons in the header row, especially to hide the panel and to minimize the application.


## More options

For generic branding, see [branding](./branding.md).
