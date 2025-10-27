---
id: wenglor-weqube
name: Wenglor weQube Smart Camera
title: Wenglor weQube Smart Camera
tags:
    - tool
    - camera
---

# Wenglor weQube Smart Camera

# Keyence IV4 AI Vision Sensor

![IV4 camera](resources/wenglor-weqube-b50.png){ align=right }
The Wenglor weQube B50 is available as a smart camera, vision sensor and OCR reader and solves a wide range of industrial image processing tasks in real time. The highly modular hardware platforms in combination with high-performance machine vision software enable tailored adjustment for all machine vision applications. You can find more details on the [Wenglor weQube B50 product page](https://www.wenglor.com/en/Machine-Vision/Smart-Cameras-and-Vision-Sensors/weQube-B50/c/cxmCID221376).

OGS controls the camera over the integrated EtherNet/IP interface. 

## IO configuration

!!! warning

    The Wenglor I/O fieldbus interface has consistency issues with data updates,
    the manual indicates that each slot is updated seperately, so not all updates
    happen at the same time!
    
!!! warning 

    The weQube camera does not configure the field bus interface globally, it is
    configured as part of the program. This requires **all** programs to have the
    identical IO configuration, else the fieldbus interface will not work correctly and switching programs will fail!
        
!!! warning

    Changing the field bus interface or data mapping requires a reboot of the camera.
    Double check, that all program use the identical fieldbus setting and data mapping!

Wenglor uses slots (like in Profinet) to configure the input and output data, but these cannot be flexibly used due to some internal restrictions of the fieldbus implementation. To make the camera fieldbus interface realiably work, the following mapping and configuration **must** be used: 

Slot 1 and Slot two are fixed as follows:

- Slot 1: `PLC -> Camera` [1 Byte output] Project number
- Slot 2: `PLC <- Camera` [4 Bytes input] Status

As there are some issues with data consistency (see the Wenglor weQube EtherNet/IP manual), slots 5 and 6 must be configured as follows (only slots 3 and slots 4 are usable for custom data):

- Slot 5: `PLC -> Camera` [1 Byte output (8 Bool)] with the following settings:
    * Bit 0 = Device Camera Trigger
- Slot 6: `PLC <- Camera` [16 Byte input (4 DINT)] with the following mapping
    * Integer 1 = Fixed value set to the program number (manually)
    * Integer 2 = Toggle Bit
    * Integer 3 = Run Counter
    * Integer 4 = Result Ok/Nok (1 = ok)

The value of `Integer 1` **must be manually set to the programs number** (the first three digits of the program name) - as the camera does not have a built-in variable to report the currently active program and there is no handshake which reports the camera is ready again after changing a program (other than doing it manually using the `Integer 1`) - see the Wenglor weQube fieldbus manual for details.

!!! warning

    To allow selecting programs over fieldbus, the program names must start with the 3-digit program numer and an underscore, i.e. `001_MyProgram`, `002_MyOtherProgram`!

![alt text](./resources/wenglor-fixedprgnum.png)

The remaining two slots 3 and 4 can be configured for parameter and output (measurement) data. By default they should be configured as follows:

- Slot 3: `PLC -> Camera` [16 Byte output (4 Real)] 
- Slot 4: `PLC <- Camera` [16 Byte input (4 Real)] 

Overall:
- `PLC -> Camera`: 1 + 1 + 16 = 18 bytes
- `PLC <- Camera`: 4 + 16 + 16 = 36 bytes

!!! warning

    The Wenglor EtherNet/IP implementation requires you to manually define the module types (again, seems that this is a non-optimized HMS AnyBus implementation). 

As outlines above, slots 5 and 6 must be configured as module type 8 and 1 respectively, slots 3 and 4 by default as 7 and 2. Here is a sample screenshot from a CoDeSys controller:

![alt text](./resources/wenglor-slotsettings.png)

Here is the table from the official manual:

![alt text](./resources/wenglor-moduletypes.png)

Note, that either data size or module types do not match, the EtherNet/IP connection will not be successful (and there is **no** diagnosics on the cameras web interface) !

## Result and image access

The camera provides an integrated webserver which allows access to the current camera image as well as a (configurable) visualization page with the last analysis result.

### Current image

The cameras current image can be accessed through the URL `http://<camera-ip>/liveimage.htm` (or the image as jpg at `http://<camera-ip>/live_image.jpg`):

![alt text](./resources/wenglor-liveimage.png)


### Analysis result

The latest analysis result can be accessed through the URL `http://<camera-ip>/Visualization/`:

![alt text](./resources/wenglor-visualization.png)


## Device settings

The device settings can be accessed through `http://<camera-ip>/device.htm`.

Default username and passwords are:
- user: admin
- password: admin

!!! warning

    Changing the DHCP settings does not work reliably from within the web page device settings, nor does it work through the cameras display/buttons. The only way to reliably change the network settings was using the windows application `uniVision 2` and selecting the `properties` button in the start dialog, then changing the parameters there.

