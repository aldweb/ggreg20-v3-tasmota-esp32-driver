#-
-----------------------------------------------------
| GGreg20_V3 Geiger Counter driver written in Berry |
|   coded by aldweb (Feb 28th, 2023)                |
-----------------------------------------------------

aldweb upgrade #2
- new: full rewrite of the driver, to clean and beautify code
- new: include CPM 5 minutes average

aldweb upgrade #1
- fix: if the native temperature sensor of the ESP32 is not shown (SetOption146 0), then the driver would fail to run, this is corrected
- fix: as explained by distrubi (https://github.com/iotdevicesdev/ggreg20-v3-tasmota-esp32-driver/pull/1), "the calculated dose was waaaay too low", his fix - which also softcodes the conversion factor - was integrated
- new: since CPM count is reset every 60 seconds, added a time counter, which is basically to just display the value stored in the ctr variable
-#

tasmota.cmd('counter1 0')

# Tubes can vary (+-20%) so recommendation is to use a conversion factor between 0.0054 and 0.0092 and to calibrate the calculations with a trusted (certified) device
var GGpowerfactor = 0.0073 # 0.0073 = 0.0054 + (0.0092-0.0054)/2
var GGtimer = 0
var GGcounter = 0
var GGcpt = 0
var GGpower = 0
var GGdose = 0
var GGcpm1 = 0
var GGcpm5 = 0
var GGpwr1 = 0
var GGpwr5 = 0
var GG5ptr = 1
GGcpm5data = {}
GGpwr5data = {}


class GGREG20_V3 : Driver
  #  print(tasmota.read_sensors())
  
  #- read and calculate accordingly -#
  def read_power()
    import string
    var i = number(string.find(tasmota.read_sensors(), "C1")+4)
    var counterstr = ''
    var pwr5sum = 0
    var cpm5sum = 0
    while tasmota.read_sensors()[i] != "}"
      counterstr = counterstr + tasmota.read_sensors()[i]
      i = i + 1
    end
    var counter = number(counterstr)
    if GGtimer >= 60
      GGcpm1 = GGcpt
      GGcpm5data[GG5ptr] = GGcpt
      GGpwr1 = GGpower
      GGpwr5data[GG5ptr] = GGpower
      var j = 1
      while j <= size(GGpwr5data)
        pwr5sum = pwr5sum + GGpwr5data[j]
        cpm5sum = cpm5sum + GGcpm5data[j]
        j = j + 1
      end
      GGpwr5 = pwr5sum / size(GGpwr5data)
      GGcpm5 = cpm5sum / size(GGcpm5data)
      if GG5ptr <= 4
        GG5ptr = GG5ptr + 1
      else
        GG5ptr = 1
      end
      GGdose = GGdose + (GGpower / 60)
      GGcounter = counter
      GGtimer = 0
    end
    GGcpt = counter - GGcounter
    GGpower = GGcpt * GGpowerfactor
  end

  #- trigger a read every second -#
  def every_second()
    self.read_power()
    GGtimer = GGtimer + 1
  end

  #- display sensor value in the web UI -#
  def web_sensor()
    import string
    var msg = string.format(
      "{s}GGreg20_V3 timer{m}%i seconds{e}"
      "{s}GGreg20_V3 cpt{m}%i CpT{e}"
      "{s}GGreg20_V3 powert{m}%1.3f uSv/h{e}"
      "{s}GGreg20_V3 cpm1m{m}%i CpM{e}"
      "{s}GGreg20_V3 power1m{m}%1.3f uSv/h{e}"
      "{s}GGreg20_V3 cpm5m{m}%i CpM{e}"
      "{s}GGreg20_V3 power5m{m}%1.3f uSv/h{e}"
      "{s}GGreg20_V3 dose{m}%1.4f uSv{e}",
      GGtimer, GGcpt, GGpower, GGcpm1, GGpwr1, GGcpm5, GGpwr5, GGdose)
    tasmota.web_send_decimal(msg)
  end

  #- add sensor value to teleperiod -#
  def json_append()
    import string
    var msg = string.format(",\"GGreg20_V3\":{\"sec\":%i,\"cpt\":%i,\"powert\":%1.3f,\"cpm1m\":%i,\"power1m\":%1.3f,\"cpm5m\":%i,\"power5m\":%1.3f,\"dose\":%1.4f}", GGtimer, GGcpt, GGpower, GGcpm1, GGpwr1, GGcpm5, GGpwr5, GGdose)
    tasmota.response_append(msg)
  end

end
GGREG20_V3 = GGREG20_V3()
tasmota.add_driver(GGREG20_V3)
