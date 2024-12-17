# ggreg20-v3-tasmota-esp32-driver

This is a repository for an upgrade proposal for the great GGreg20_V3 and ESP32 Tasmota Firmware driver
https://github.com/iotdevicesdev/ggreg20-v3-tasmota-esp32-driver

aldweb upgrade #1:
- fix: if the native temperature sensor of the ESP32 is not shown (SetOption146 0), then the driver would fail to run, this is corrected
- fix: as explained by distrubi (https://github.com/iotdevicesdev/ggreg20-v3-tasmota-esp32-driver/pull/1), "the calculated dose was waaaay too low", his fix - which also softcodes the conversion factor - was integrated
- new: since CPM count is reset every 60 seconds, added a time counter, which is basically to just display the value stored in the ctr variable
 
aldweb upgrade #2:
- new: full rewrite of the driver, to clean and beautify code
- new: include CPM 5 minutes average
- new: include Power and CPM 1 minute averages
 
 aldweb upgrade #3
- change: memory and code optimized
- new: 5 minutes CPM precision set to 1 digit after the decimal point
- cosmetic change: from "uSv" to "µSv"

aldweb upgrade #4
- change: calibration factor upgraded to 0.00812
- added: explanation and quick rule coding for integration between Tasmota and GMC.MAP (https://www.gmcmap.com/)

![image](https://github.com/aldweb/ggreg20-v3-tasmota-esp32-driver/assets/61916846/6811029b-7256-4a31-b691-b141e6b211cb)
