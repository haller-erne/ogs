---
id: station_io
name: Station IO
title: Station IO
tags:
    - appnote
---

# Station IO

## Overview

Many times, a real world installation of OGS needs to interact with external sensors and actuators. Typical samples are external push buttons (to acknowledge an operation) connected to a remote I/O module or positioning sensors connected over EtherNet/IP.

To simplify access to external IO, OGS provides two generic LUA modules to interact with Modbus/TCP and EtherNet/IP based remote IO devices.

These modules provide the following:

- Configuration of the devices (like IP address and register scanlist) in `station.ini`
- Cyclic data exchange in the background (not blocking LUA processing)
- A LUA interface to add application specific code for mapping input/output data and connecting the physical IOs to a logical OGS function 

Currently the following modules are available (see below for more details on using them):

- `station_io_enip.lua`: Handle Ethernet/IP remote IO devices using a class 1 (implicit) connection. IP addresses are configurable through station.ini. A set of 'known' devices is included, but others can be added (by specifying the CIP forward open parameters).
- `station_io_modbus.lua`: Handle Modbus/TCP remote I/O devices. IP addresses and scan list (registers to be scanned cyclically) are configurable through station.ini.

!!! Info

    Note, that you can also use the OpenProtocol custom IO signals for IO. This is not covered here, see the [OpenProtocol tools](/ogs/tools/openprotocol/) section for more information.

## Usage

The recommended way to use the station IO modules is to create a station specific `station_io.lua` file and add this to the `config.lua` requires list.



## station_io_enip



## station_io_modbus




