disableSerialization;

_listBox = _this select 0;
_index = _this select 1;

_vehicleClass = _listBox lbData _index;

_vehicleClass call ExileClient_gui_vehicleTraderDialog_updateVehicle;

true