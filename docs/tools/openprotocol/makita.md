---
id: makita
name: Makita DFT/DFL wifi battery clutch tool
title: Makita DFT/DFL wifi battery clutch tool
tags:
    - tool
    - tightening
    - openprotocol
---

# Makita DFT/DFL wifi battery clutch tool

!!! info

    This page describes the specifics for configuring the Makita 18V wifi battery tools to work with OGS, for general information about the OGS OpenProtocol configuration, see [OpenProtocol Tools](README.md).


## Overview

![Makita tools](resources/makita.png){ width="200", align=right }
The [Makita](https://www.makita.com) industrial [18V battery clutch tools](https://www.makita.de/data/pam/public/01_kataloge/801425_industrieprospekt_2024_dz_online.pdf) of the `FM4Z` series provide wifi connectivity including OpenProtocol interface support through the [MTC wifi module](https://www.visiondevices.de/seo/produkte/micro-tool-controller/). The clutch tools are available as pistol and angle tools in the range of 0.5-12/40Nm. The speed is programmable to support hard and soft joints, the accuracy is +/- 10% (Cmk > 1.67, VDI/VDE 2647).   

To access the configuration, use the integrated web server of the tool. If the tool is already connected to the wifi, enter its IP address, else connect the USB-C interface of the MTC module. Connecting the tool over USB will load a new RNDIS USB network interface and allows connecting to the tool at the predefined IP address http://192.168.7.1/. After the webbrowser is connected, enter the credentials (default user/password: user/user) to log in:

![alt text](resources/makita-login.png)

After logging in, the main page is shown - the configuration is accessible through the buttons `App_Setup` and `Ctrl_Setup`.

![alt text](resources/makita-home.png)

To configure the Wifi settings (or read the current settings), select the `Ctrl_Setup` button, else go to `App_Setup` to configure the OpenProtocol settings and the tightening parameters. Here are two sample screenshots from the Wifi configuration:
![alt text](resources/makita-wifi-info.png){ width="100" }
![alt text](resources/makita-wifi.png){ width="100" }


## OpenProtocol setup

To enable the OpenProtocol interface, select the `App_Setup --> Protocol` and select `OpenProtocol` from the protocol dropdown and click `Submit` to update the configuration. 

![alt text](resources/makita-openprotocol.png)

Then navigate to `Setup` (from the lefthand navigation menu) - this allows configuring the OpenProtocol parameters:

![alt text](resources/makita-settings.png)

The most important settings here are:

- `Supplier Code`: Make sure to set this to `AAA`
- `Server Port`: This is the OpenProtocol listening port, should be set to `4545` (this must match the setting in station.ini, see below)

## Program definition

### Nok/acknowledge/retry parameters 


Note: for the login to work, make sure OGS is stopped.



![alt text](resources/makita-pset.png)
![alt text](resources/makita-program.png)
