

#    ###################################################################################
#    Antonov-Aircrafts and SpaceShuttle :: Herbert Wagner November2014-March2015
#    Development is ongoing, see latest version: www.github.com/HerbyW
#    This file is licenced under the terms of the GNU General Public Licence V3 or later
#    ###################################################################################

setlistener("/controls/engines/engine/propeller-pitch", func
 {
    setprop("/fdm/jsbsim/propulsion/engine/propeller-pitch", getprop("/controls/engines/engine/propeller-pitch"));
 });



setprop("/sim/signals/fdm-ready", 0);


var fdmready = maketimer(3, func {
  
  if (getprop ("/sim/time/elapsed-sec") > 10 )  
  setprop("/sim/signals/fdm-ready", 1); 
    
});

fdmready.start();

#UVID-15 Control for Pressure in mmhg and inhg
# create listener

setlistener("/instrumentation/altimeter/setting-inhg", func(v)
{
  if(v.getValue())
  
    setprop("/instrumentation/altimeter/mmhg", getprop("/instrumentation/altimeter/setting-inhg") * 25.4);
    setprop("/instrumentation/altimeter/setting-inhgN", getprop("/instrumentation/altimeter/setting-inhg") + 0.005);
    setprop("/instrumentation/altimeter/setting-hapa", getprop("/instrumentation/altimeter/setting-inhg") * 33.8682715);
});

#####################################################################################################################

#UVPD Control
# create timer with 0.5 second interval
var timerDiff = maketimer(0.5, func

{ 
    setprop("/controls/pressurization/diffdruck", (1 / getprop("/environment/atmosphere/density-tropo-avg") - 1.58));    
  }
);

# start the timer (with 0.5 second inverval)
timerDiff.start();

######################################################################################################################

#
# Air and Groundspeed selector for USVP-Instrument
#
setlistener("/controls/switches/usvp-selector-trans", func 

  { if(getprop("/controls/switches/usvp-selector-trans") > 0.5)
      {
        setprop("/instrumentation/usvp/air_ground_speed_kt", getprop("/velocities/groundspeed-kt"));
      }
      else
      {
        setprop("/instrumentation/usvp/air_ground_speed_kt", getprop("/instrumentation/airspeed-indicator/indicated-speed-kt"));
      }
  
  }
  );
 
#####################################################################################################################

#Lights
setprop("controls/switches/headlight-mode", 1);

######################################################################################################################

##########################################################
#      ALS Control by HerbyW 03/2015
##########################################################

setlistener("/controls/ALS/setting", func(v) {
  if(v.getValue()){
    interpolate("/controls/ALS/setting-pos", 1, 0.25);
  }else{
    interpolate("/controls/ALS/setting-pos", 0, 0.25);
  }
});


setlistener("controls/ALS/setting", func

 { 
   if(getprop("sim/rendering/rembrandt/enabled") == 1)
    {
      setprop("sim/messages/copilot", "ALS is not working with Rembrandt");
    }
    else
    { 
      if(getprop("controls/ALS/setting") == 1)
      {
      setprop("sim/rendering/shaders/skydome", 1);
      setprop("sim/rendering/als-secondary-lights/landing-light1-offset-deg", -12);
      setprop("sim/rendering/als-secondary-lights/landing-light2-offset-deg", 12);
      setprop("sim/rendering/als-secondary-lights/use-alt-landing-light", 1);
      setprop("sim/rendering/als-secondary-lights/use-landing-light", 1);
      setprop("sim/rendering/als-secondary-lights/use-searchlight", 1);
      }
      else
      {
      setprop("sim/rendering/als-secondary-lights/use-alt-landing-light", 0);
      setprop("sim/rendering/als-secondary-lights/use-landing-light", 0);
      setprop("sim/rendering/als-secondary-lights/use-searchlight", 0);
      }
    }   

 }
);


########################################################################################################

# Parking Chokes and Brake Control

setlistener("controls/gear/brake-parking", func

{ if (getprop("/sim/replay/replay-state") == 0)

{
   if (getprop("/controls/gear/brake-parking") == 0)
    {
      if (getprop("/controls/chokes/activ") == 1)
        {
	  setprop("sim/messages/copilot", "Parking Chokes are at the wheels! Parking Brake can not be lift");
          setprop("/controls/gear/brake-parking", 1);
        }
      else
        {
	  setprop("sim/messages/copilot", "Parking Brake off, aircraft is moving!");
	  setprop("/controls/gear/brake-parking", 0);  
	}
     }
    else
     {
       if (getprop("/position/altitude-agl-ft") > 5)
        {
	 setprop("sim/messages/copilot", "We are in the air, Brakes have no sense...");
	 setprop("/controls/gear/brake-parking", 0);
        }
       else
        {
	  setprop("sim/messages/copilot", "Parking Brake on, check if chokes are needed!");
	}
     } 
}});  

setlistener("/controls/chokes/activ", func

{ if (getprop("/sim/replay/replay-state") == 0)
{
   if (getprop("/controls/chokes/activ") == 1)
   if (getprop("/controls/gear/brake-parking") == 0)
        {
	  setprop("sim/messages/copilot", "Parking Brake off, Chokes can not be set!");
	  setprop("/controls/chokes/activ", 0);  
	}
    if (getprop("/controls/chokes/activ") == 1)
    if (getprop("/controls/gear/brake-parking") == 1)
        {
	  setprop("sim/messages/copilot", "Parking Brake and Chokes are set, enjoy your day!");
	}
}});

########################################################################################################

# Landing Gears Control with help from: 707 Hangar of Constance

# prevent retraction of the landing gear when any of the wheels are compressed
setlistener("controls/gear/gear-down", func
 {
 var down = props.globals.getNode("controls/gear/gear-down").getBoolValue();
 var crashed = getprop("sim/crashed") or 0;
 if (!down and (getprop("gear/gear[0]/wow") or getprop("gear/gear[1]/wow") or getprop("gear/gear[2]/wow")))
  {
    if(!crashed){
  		props.globals.getNode("controls/gear/gear-down").setBoolValue(1);
    }else{
  		props.globals.getNode("controls/gear/gear-down").setBoolValue(0);
    }
  }
 });
 


#############################################################################################################
#
# wind drift angle calculations, with help from: D-LEON
#
# wind direction:  environment/metar/base wind-dir-deg
# wind speed:      environment/metar/base wind-speed-kt
# heading:         orientation/heading-deg
# speed:           instrumentation/airspeed-indicator/indicated-speed-kt

#
#Calculate Ground Speed, Course & Wind Correction Angle
# create timer with 0.7 second interval
setprop("/autopilot/settings/heading-bug-deg", 0.001);

var TODEG = 180/math.pi;
var TORAD = math.pi/180;
var deg = func(rad){ return rad*TODEG; }
var rad = func(deg){ return deg*TORAD; }

var calc = maketimer(0.7, func

{ 
 
  var TWD 	= rad(getprop("/environment/wind-from-heading-deg"));
  var WS 	= getprop("/environment/wind-speed-kt");
  var TC 	= rad(getprop("/autopilot/settings/heading-bug-deg"));

  var TAS	= getprop("/instrumentation/airspeed-indicator/true-speed-kt");
  var MD 	= rad(getprop("/environment/magnetic-variation-deg"));  
  
  var x = WS * math.sin((TC-TWD));
  var y = TAS - (WS * math.cos((TC-TWD))); 
  
  DA = math.atan2(x,y);  
    
  if  
    (getprop("/instrumentation/airspeed-indicator/true-speed-kt") < 25 )
    { setprop("/instrumentation/drift",0 );}
  else
  { setprop("/instrumentation/drift",deg(DA)); }
  
}
);

# start the timer (with 0.7 second inverval)
calc.start();


#################################################################################################################


setprop("sim/messages/copilot", "Hello");
setprop("sim/messages/copilot", getprop("sim/multiplay/generic/string[0]"));
setprop("sim/messages/copilot", "Have fun with the Yak-58.");
setprop("sim/messages/copilot", "For Autostart hit the S key and then s for starting the engine!");


####################################################################################################################

# Lake of Constance Hangar :: M.Kraus
# April 2013
# This file is licenced under the terms of the GNU General Public Licence V2 or later
# ============================================
# The analog watch for the flightgear - rallye 
# ============================================
var sw = "/instrumentation/stopwatch/";


#============================== only stopwatch actions ================================
var sw_start_stop = func {
  var running = props.globals.getNode(sw~"running");

  if(!running.getBoolValue()){
    # start
    setprop(sw~"flight-time/start-time", getprop("/sim/time/elapsed-sec"));
    running.setBoolValue(1);
    sw_loop();
  }else{
    # stop
    var accu = getprop(sw~"flight-time/accu");
    accu += getprop("/sim/time/elapsed-sec") - getprop(sw~"flight-time/start-time");
    setprop(sw~"running",0);
    setprop(sw~"flight-time/accu", accu);
    sw_show(accu);
  }
}

var sw_reset = func {
  var running = props.globals.getNode(sw~"running");
  setprop(sw~"flight-time/accu", 0);

  if(running.getBoolValue()){
    setprop(sw~"flight-time/start-time", getprop("/sim/time/elapsed-sec"));
  }else{
    sw_show(0);
  }
}

var sw_loop = func {
  var running = props.globals.getNode(sw~"running");
  if(running.getBoolValue()){
    sw_show(getprop("/sim/time/elapsed-sec") - getprop(sw~"flight-time/start-time") + getprop(sw~"flight-time/accu"));
    settimer(sw_loop, 0.04);
  }
}

var sw_show = func(s) {
  var hours = s / 3600;
  var minutes = int(math.mod(s / 60, 60));
  var seconds = int(math.mod(s, 60));

  setprop(sw~"flight-time/total",s);
  setprop(sw~"flight-time/hours",hours);
  setprop(sw~"flight-time/minutes",minutes);
  setprop(sw~"flight-time/seconds",seconds);
}

#############################################################################################################
setprop("/autopilot/settings/target-altitude-ft", 0);

var adjustStep = func(value,amount,step=10){

if (math.abs(amount) >= step){
if (math.mod(value,step) != 0){
if (amount > 0){
value = math.ceil(value/step)*step;
}else{
value = math.floor(value/step)*step;
}
}else{
value += amount;
}
}else{
value += amount;
}
return value;
};


var adjustAlt = func(amount,step=100){

var value = getprop("/autopilot/settings/target-altitude-ft");
value = adjustStep(value,amount,100);
setprop("/autopilot/settings/target-altitude-ft",value);


};


var adjustPitch = func(amount,step=100){

var value = getprop("/autopilot/settings/vertical-speed-fpm");
value = adjustStep(value,amount,100);
setprop("/autopilot/settings/vertical-speed-fpm",value);


};

##############################################################################################################


setlistener("/sim/airport/closest-airport-id", func
{
  setprop("/controls/switches/metar",1);  
}
);

########################################################################################################

# Flaps Control with speed limits
# prevent demage of flaps due to speed

setlistener("controls/flight/flaps", func
 { 
 if ((getprop("controls/flight/flaps") > 0  ) and (getprop("/instrumentation/airspeed-indicator/indicated-speed-kt") > 250  ))
  {
    setprop("controls/flight/flaps", 0);
    setprop("sim/messages/copilot", "Do you want to destroy the flaps due to overspeed????");    
  }
});
