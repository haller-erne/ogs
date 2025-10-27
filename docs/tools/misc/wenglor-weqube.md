---
id: wenglor-weqube
name: Wenglor weQube Smart Camera
title: Wenglor weQube Smart Camera
tags:
    - tool
    - camera
---

# Wenglor weQube Smart Camera

![alt text](resources/webglor-weqube-IO-Setting.png)

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

Wenglor uses slots (like in Profinet) to configure the input and output data, but has some quite severe limitations. 

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

![alt text](./resources/wenglow-moduletypes.png)

Note, that either data size or module types do not match, the EtherNet/IP connection will not be successful (and there is **no** diagnosics on the cameras web interface) !

