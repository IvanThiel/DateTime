using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.Communications as Comm;
using Toybox.System as Sys;
using Toybox.Time;
using Toybox.Time.Gregorian;
using Toybox.Math;
using Toybox.Application as App;
using Toybox.Position;
using Toybox.Background;
using Toybox.Application.Storage;



var GlobalTouched = -1;
var mW;
var mH;
var _debug = false;
var _sound = false;     

class DateTimeView extends Ui.DataField {

    hidden var YMARGING      = 3;
    hidden var XMARGINGL     = 6;
    hidden var mCurrentLocation = null;
    hidden var mShowType = 0;

    /******************************************************************
     * INIT 
     ******************************************************************/  
    function initialize() {
      try {
        DataField.initialize();  

        //mBikeRadar = new AntPlus.BikeRadar(new CombiSpeedRadarListener()); 
      } catch (ex) {
        debug ("init error: "+ex.getErrorMessage());
      }         
    }

    /******************************************************************
     * HELPERS 
     ******************************************************************/  
    function debug (s) {
      try {
        if (_debug) {
          System.println("DateTimeApp: "+s);
        } 
        if (s.find(" error:")!=null) {
          if (_sound) {
            Attention.playTone(Attention.TONE_ERROR);
          }
          if (!_debug) {
            System.println("=== ERROR =================================================================");
            var now = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
            var v = now.hour.format("%02d")+":"+now.min.format("%02d")+":"+now.sec.format("%02d");
            System.println(v);
            System.println(""+s);
            System.println("DateTimeView: "+s);
            System.println("===========================================================================");
          }
        }
      } catch (ex) {
        System.println("debug error:"+ex.getErrorMessage());
      }
    }

    function trim (s) {
      var l = s.length();
      var n = l;
      var m = 0;
      var stop;

      stop = false;
      for (var i=0; i<l; i+=1) {
        if (!stop) {
          if (s.substring(i, i+1).equals(" ")) {
            m = i+1;
          } else {
            stop = true;
          }
        }
      }

      stop = false;
      for (var i=l-1; i>0; i-=1) {
        if (!stop) {
          if (s.substring(i, i+1).equals(" ")) {
            n = i;
          } else {
            stop = true;
          }
        }
      }  

      if (n>m) {
        return s.substring(m, n);  
      } else {
        return "";
      }
    }

    function stringReplace(str, oldString, newString) {
      var result = str;

      while (true) {
        var index = result.find(oldString);

        if (index != null) {
          var index2 = index+oldString.length();
          result = result.substring(0, index) + newString + result.substring(index2, result.length());
        }
        else {
          return result;
        }
      }

      return null;
    }


    /******************************************************************
     * DRAW HELPERS 
     ******************************************************************/  
    function setStdColor (dc) {
      if (getBackgroundColor() == Gfx.COLOR_BLACK) {
         dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
      } else {
          dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
      }   
    }

    /******************************************************************
     * VALUES 
     ******************************************************************/  
    
    function drawValues (dc) {
      try {
        var x = mW/2;
        var f = Gfx.FONT_GLANCE_NUMBER;
        var h = dc.getTextDimensions("X", f)[1];
        var type = mShowType;
        var c = Weather.getCurrentConditions();  
        
        if ((type==0) || (mCurrentLocation == null) || (c==null)) {
          var today = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
          var dateString = "";

          // Ma
          dateString = Lang.format(
            "$1$",
            [
              today.day_of_week.toUpper()
            ]);

          dc.drawText(x, mH/2-h * 1.5, f, dateString, Gfx.TEXT_JUSTIFY_CENTER);  

          // 15 Jul
          dateString = Lang.format(
            "$1$ $2$",
            [
              today.day,
              today.month.toUpper()
            ]);

          dc.drawText(x, mH/2-h * 0.5, f, dateString, Gfx.TEXT_JUSTIFY_CENTER);  

          // 11:12:00
          dateString = Lang.format(
            "$1$:$2$:$3$",
            [
              today.hour,
              today.min.format("%02d"),
              today.sec.format("%02d")
            ]);

          dc.drawText(x, mH/2-h*-0.5, f, dateString, Gfx.TEXT_JUSTIFY_CENTER); 
         }

         if ((type==1) && (mCurrentLocation != null) && (c!=null)) {
          var date;
          var dateString;
          

          dc.drawText(x, mH/2-h * 1.5, f, "RISE/SET", Gfx.TEXT_JUSTIFY_CENTER);  

          // Sunrise
          date = c.getSunrise(mCurrentLocation, Time.now());
          date = Gregorian.info(date, Time.FORMAT_MEDIUM);
          dateString = Lang.format(
            "$1$:$2$",
            [
              date.hour,
              date.min.format("%02d"),
            ]);
          dc.drawText(x, mH/2-h * 0.5, f, dateString, Gfx.TEXT_JUSTIFY_CENTER);  
          
          // Sunset
          date = c.getSunset(mCurrentLocation, Time.now());
          date = Gregorian.info(date, Time.FORMAT_MEDIUM);
          dateString = Lang.format(
            "$1$:$2$",
            [
              date.hour,
              date.min.format("%02d"),
            ]);
          dc.drawText(x, mH/2-h * -0.5, f, dateString, Gfx.TEXT_JUSTIFY_CENTER);  

         }
      } catch (ex) {
        debug("drawValues error "+ex.getErrorMessage());
      }
    }

    /******************************************************************
     * COMPUTE 
     ******************************************************************/  
    
    function getLastKnownLocation(info) {
      if (
          (info.currentLocation!=null) && 
          (info.currentLocation.toDegrees()[0].toNumber()!=0) 
         // (info.currentLocation.toDegrees()[1].toNumber()!=-94) // Garmin default
         ) 
     {
        Storage.setValue("lastknown_lat_2" , info.currentLocation.toDegrees()[0].toFloat());
        Storage.setValue("lastknown_long_2", info.currentLocation.toDegrees()[1].toFloat());
        return info.currentLocation;
      } else {
        var lat  = Storage.getValue("lastknown_lat_2");
        var long = Storage.getValue("lastknown_long_2");
        if ((lat!=null) && (long!=null)) {
          return  new Position.Location( {
                :latitude  => lat,
                :longitude => long,
                :format    => :degrees
              });
        } else {
          return  new Position.Location( {
                :latitude  => 52.100092,
                :longitude => 5.135507,
                :format    => :degrees
              });
        }
      }
      return null;
    }

    function compute(info) {
      try {  
        mCurrentLocation = getLastKnownLocation(info);
      } catch (ex) {
          debug("Compute error: "+ex.getErrorMessage());
      }                  
    }
    
    /******************************************************************
     * Event handlers 
     ******************************************************************/  
    function onTimer() {
    }

    function onTimerLap() {   
      debug("onTimerLap");
    }   

    function onTimerPause() {     
      debug("onTimerPause");
    }   

    function onTimerReset() {     
      debug("onTimerReset");
    }   

    function onTimerResume() {     
      debug("onTimerResume");
    }   

    function onTimerStart() {  
      debug("onTimerStart");
    }   

    function onTimerStop() {     
      debug("onTimerStop");
    }    

    function onShow() as Void {
      debug("onShow");
    }   

    function onHide() as Void {
      debug("onHide");
    }   

    /******************************************************************
     * On Update
     ******************************************************************/  
  

    function handleTouch() {
      try {
        if (GlobalTouched>=0) {
          GlobalTouched = -1;
          mShowType ++;
          if (mShowType>1) {
            mShowType = 0;
          }
        } 
      } catch (ex) {
        GlobalTouched = -1;
        debug("handleTouch error: "+ex.getErrorMessage());
      }
    }

    function onUpdate(dc) { 
      try {  
        mW = dc.getWidth();
        mH = dc.getHeight();
        dc.setColor(getBackgroundColor(), getBackgroundColor());
        dc.clear();
        setStdColor(dc);
        handleTouch();
        try { 
          drawValues(dc);
        } catch (ex) {
          debug("onUpdate draw error: "+ex.getErrorMessage());
        }    
       
      } catch (ex) {
        debug("onUpdate ALL error: "+ex.getErrorMessage());
     }
    }

}
