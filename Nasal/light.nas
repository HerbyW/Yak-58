
var LightBeacon = props.globals.initNode("/controls/lighting/switches/beacon",0,"BOOL");
var LightStrobe = props.globals.initNode("/controls/lighting/switches/strobe",0,"BOOL");
var strobe_switch = props.globals.getNode("/controls/lighting/strobe", 1);
aircraft.light.new("/controls/lighting/strobe-state", [0.05, 1.20], strobe_switch);
var beacon_switch = props.globals.getNode("/controls/lighting/beacon", 1);
aircraft.light.new("/controls/lighting/beacon-state", [0.05, 1.8], beacon_switch);

var autoInstrumentDimmingListener = func {
    var panel = getprop('controls/lighting/panel-norm');
    var dimming = panel < 0.1 ? 0.0 : 0.7 - panel;
    if (dimming < 0) dimming = 0.0;
    setprop('instrumentation/comm[0]/dimming-norm', dimming);
    setprop('instrumentation/comm[1]/dimming-norm', dimming);
    setprop('instrumentation/dme[0]/dimming-norm', dimming);
    setprop('instrumentation/adf[0]/dimming-norm', dimming);
}

setlistener('controls/lighting/panel-norm', autoInstrumentDimmingListener);
