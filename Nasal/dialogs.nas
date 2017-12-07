# MODEL INFO

print('*************************************************************************************************'); 
print('Yakovlev Yak-58');
print('Role: Six-seat cabin monoplane'); 
print('Modern design, silent power plant, exellent visiblity from the cabin, simplicity of piloting - that is Yak-58.');
print('Piston engine with variable pitch pusher propeller MTV-23');
print('Powerplant: Vedeneyev M-14PT, 269 kW (360 hp)');
print('Type: Nine cylinder, four-stroke, air-cooled radial engine');
print('Capacity: 1 pilot and 5 passengers'); 
print('*************************************************************************************************');
print('Author: HerbyW');
print('June 2015-2017');
print('*************************************************************************************************');


# AIRCRAFT DIALOGS

var dlg = {
	checklists: gui.Dialog.new("/sim/gui/dialogs/Yak-58/checklists/dialog","Aircraft/Yak-58/Dialogs/Yak-58-checklists.xml"),
	utility: gui.Dialog.new("/sim/gui/dialogs/Yak-58/utility/dialog","Aircraft/Yak-58/Dialogs/Yak-58-utility.xml")
	};
fgcommand("loadxml", props.Node.new({filename: "Aircraft/Yak-58/Dialogs/Yak-58-checklists-text.xml", targetnode: "/sim/gui/dialogs/Yak-58/checklists-list"}));

#removed autopilot
# ,autopilot: gui.Dialog.new("/sim/gui/dialogs/Yak-58/autopilot/dialog","Aircraft/Yak-58/Dialogs/Navomatic400A-autopilot.xml")