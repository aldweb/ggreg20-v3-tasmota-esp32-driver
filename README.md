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
 
![image](https://user-images.githubusercontent.com/61916846/222277107-2c19a4fb-076b-420a-b749-9a7e47b67322.png)
