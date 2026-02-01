#-
-----------------------------------------------------
| GGreg20_V3 Geiger Counter driver written in Berry |
|   coded by aldweb (January 31st, 2026)            |
-----------------------------------------------------

aldweb upgrade #7 (v6 optimized)
- improvement: use native JSON parsing (json.load) for better performance and robustness
- improvement: encapsulate all variables in class with proper initialization
- improvement: use array [] with validity counter for correct 5-minute average
- improvement: add comprehensive error handling with try-catch
- improvement: automatic min/max tracking with persistent storage in Mem1/Mem2
- fix: 0-based array indexing (standard convention)
- fix: store sensor read once to avoid multiple calls in loop

aldweb upgrade #6
- new: added cpmin and cpmax in Tasmota response string

aldweb upgrade #5
- change: set not null initial values to avoid bad data sending to MQTT (Home Assistant receives too quick!)

aldweb upgrade #4
- change: calibration factor upgraded to 0.00812

aldweb upgrade #3
- change: memory and code optimized
- new: 5 minutes CPM precision set to 1 digit after the decimal point
- cosmetic change: from "uSv" to "µSv"

aldweb upgrade #2
- new: full rewrite of the driver, to clean and beautify code
- new: include CPM 5 minutes average
- new: include Power and CPM 1 minute averages

aldweb upgrade #1
- fix: if the native temperature sensor of the ESP32 is not shown (SetOption146 0), then the driver would fail to run, this is corrected
- fix: as explained by distrubi (https://github.com/iotdevicesdev/ggreg20-v3-tasmota-esp32-driver/pull/1), "the calculated dose was waaaay too low", his fix - which also softcodes the conversion factor - was integrated
- new: since CPM count is reset every 60 seconds, added a time counter, which is basically to just display the value stored in the ctr variable
-#

#- Tubes can vary (+-20%) so recommendation is to use a conversion factor between 0.0054 and 0.0092 
   and to calibrate the calculations with a trusted (certified) device
   if calibration not easily available, 0.0057 or 0.0065 are common values found on the www
   there is also an explanation by the manufacturer of GGreg20_V3 Geiger Counter itself, suggesting to opt in for a value of 0.00812 (https://iot-devices.com.ua/en/technical-note-how-to-calculate-the-conversion-factor-for-geiger-tube-sbm20/)
-#

class GGREG20_V3 : Driver
  static var GGpowerfactor = 0.00812
  
  # Instance variables (persistent between calls)
  var GGtimer
  var GGcounter
  var GGcpt
  var GGpower
  var GGdose
  var GGcpm1
  var GGcpm5
  var GGpwr1
  var GGpwr5
  var GG5ptr
  var GG5count      # Number of valid data points in buffer (0-5)
  var GGcpm5data
  var GGcpmin       # Minimum CPM5 observed (persistent in Mem1)
  var GGcpmax       # Maximum CPM5 observed (persistent in Mem2)
  
  #- initial setup -#
  def init()
    # Initialize counter
    tasmota.cmd('counter1 0')
    
    # Initialize variables with realistic values (for Home Assistant)
    # 25 CPM ≈ 0.203 µSv/h (typical background radiation)
    self.GGtimer = 0
    self.GGcounter = 0
    self.GGcpt = 0
    self.GGpower = 0
    self.GGdose = 0
    self.GGcpm1 = 25          # Non-zero initial value
    self.GGcpm5 = 25          # Non-zero initial value
    self.GGpwr1 = self.GGcpm1 * self.GGpowerfactor
    self.GGpwr5 = self.GGcpm5 * self.GGpowerfactor
    self.GG5ptr = 0
    self.GG5count = 0
    self.GGcpm5data = [0, 0, 0, 0, 0]
    
    # Read min/max from Tasmota persistent memory
    # These values persist across reboots
    self.GGcpmin = number(tasmota.cmd('Mem1')['Mem1'])
    self.GGcpmax = number(tasmota.cmd('Mem2')['Mem2'])
    
    # First-time initialization: if BOTH are 0, it's first use
    # Set to 25 CPM (typical background radiation - realistic initial value)
    if self.GGcpmin == 0 && self.GGcpmax == 0
      tasmota.cmd('Mem1 25')
      tasmota.cmd('Mem2 25')
      self.GGcpmin = 25
      self.GGcpmax = 25
    end
    
    # Send initial values to MQTT immediately (for Home Assistant)
    self.json_append()
  end
  
  #- Read counter value using native JSON parsing -#
  def read_counter_value()
    import json
    
    try
      # Parse JSON from sensors
      var sensors = json.load(tasmota.read_sensors())
      
      # Navigate to counter value with proper error checking
      if sensors != nil && 
         sensors.contains("COUNTER") && 
         sensors["COUNTER"].contains("C1")
        return sensors["COUNTER"]["C1"]
      end
    except .. as e, m
      # Silent error handling - uncomment for debugging
      # print("GGreg20 JSON error:", m)
    end
    
    return nil
  end
  
  #- read and calculate accordingly -#
  def read_power()
    var counter = self.read_counter_value()
    
    # Skip this cycle if counter reading failed
    if counter == nil
      return
    end
    
    var cpm5sum = 0
    
    if self.GGtimer >= 60
      # Store current count in circular buffer
      self.GGcpm5data[self.GG5ptr] = self.GGcpt
      
      # Increment valid data counter (max 5)
      if self.GG5count < 5
        self.GG5count = self.GG5count + 1
      end
      
      # Store 1-minute values
      self.GGcpm1 = self.GGcpt
      self.GGpwr1 = self.GGpower
      
      # Calculate 5-minute average over valid data only
      # This ensures correct average during first 5 minutes
      var j = 0
      while j < self.GG5count
        cpm5sum = cpm5sum + self.GGcpm5data[j]
        j = j + 1
      end
      self.GGcpm5 = 1.0 * cpm5sum / self.GG5count
      self.GGpwr5 = self.GGcpm5 * self.GGpowerfactor
      
      # Update circular buffer pointer (0-based indexing)
      if self.GG5ptr >= 4
        self.GG5ptr = 0
      else
        self.GG5ptr = self.GG5ptr + 1
      end
      
      # Accumulate dose (µSv)
      self.GGdose = self.GGdose + (self.GGpower / 60)
      
      # Save counter value and reset timer
      self.GGcounter = counter
      self.GGtimer = 0
      
      # Refresh min/max thresholds from memory (allows runtime update)
      self.GGcpmin = number(tasmota.cmd('Mem1')['Mem1'])
      self.GGcpmax = number(tasmota.cmd('Mem2')['Mem2'])      
            
      # Update min/max tracking with automatic persistence
      # Check and update minimum
      if self.GGcpm5 < self.GGcpmin
        self.GGcpmin = self.GGcpm5
        tasmota.cmd('Mem1 ' + str(self.GGcpmin))
      end
      
      # Check and update maximum
      if self.GGcpm5 > self.GGcpmax
        self.GGcpmax = self.GGcpm5
        tasmota.cmd('Mem2 ' + str(self.GGcpmax))
      end
    end
    
    # Calculate current counts and power
    self.GGcpt = counter - self.GGcounter
    self.GGpower = self.GGcpt * self.GGpowerfactor
  end

  #- trigger a read every second -#
  def every_second()
    self.read_power()
    self.GGtimer = self.GGtimer + 1
  end

  #- display sensor value in the web UI -#
  def web_sensor()
    import string
    var msg = string.format(
      "{s}GGreg20_V3 timer{m}%i seconds{e}"
      "{s}GGreg20_V3 cpt{m}%i CpT{e}"
      "{s}GGreg20_V3 powert{m}%1.3f µSv/h{e}"
      "{s}GGreg20_V3 cpm1m{m}%i CpM{e}"
      "{s}GGreg20_V3 power1m{m}%1.3f µSv/h{e}"
      "{s}GGreg20_V3 cpm5m{m}%1.1f CpM{e}"
      "{s}GGreg20_V3 power5m{m}%1.3f µSv/h{e}"
      "{s}GGreg20_V3 dose{m}%1.4f µSv{e}"
      "{s}GGreg20_V3 cpmin{m}%1.1f CpM{e}"
      "{s}GGreg20_V3 cpmax{m}%1.1f CpM{e}",
      self.GGtimer, self.GGcpt, self.GGpower, 
      self.GGcpm1, self.GGpwr1, 
      self.GGcpm5, self.GGpwr5, 
      self.GGdose,
      self.GGcpmin, self.GGcpmax)
    tasmota.web_send_decimal(msg)
  end

  #- add sensor value to teleperiod -#
  def json_append()
    import string
    var msg = string.format(
      ",\"GGreg20_V3\":{\"sec\":%i,\"cpt\":%i,\"powert\":%1.3f,\"cpm1m\":%i,\"power1m\":%1.3f,\"cpm5m\":%1.1f,\"power5m\":%1.3f,\"dose\":%1.4f,\"cpmin\":%1.1f,\"cpmax\":%1.1f}", 
      self.GGtimer, self.GGcpt, self.GGpower, 
      self.GGcpm1, self.GGpwr1, 
      self.GGcpm5, self.GGpwr5, 
      self.GGdose,
      self.GGcpmin, self.GGcpmax)
    tasmota.response_append(msg)
  end

end

GGREG20_V3 = GGREG20_V3()
tasmota.add_driver(GGREG20_V3)
