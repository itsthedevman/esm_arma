disableSerialization;

_comboBox = _this select 0;
_index = _this select 1;

_categoryClass = _comboBox lbData _index;

[_categoryClass] call ExileClient_gui_vehicleTraderDialog_updateVehicleListBox;

true