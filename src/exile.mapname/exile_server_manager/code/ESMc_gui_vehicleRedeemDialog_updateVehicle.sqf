/* ----------------------------------------------------------------------------
Function:
	ESMc_gui_vehicleRedeemDialog_updateVehicle

Description:
	TODO

Author:
	Exile Mod
	www.exilemod.com
	© 2015-current_year!() Exile Mod Team

	This work is licensed under the Creative Commons Attribution-NonCommercial-NoDerivatives 4.0 International License.
	To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-nd/4.0/.

Co-author:
	Exile Server Manager
	www.esmbot.com
	© 2018-current_year!() Bryan "WolfkillArcadia"

	This work is licensed under the Creative Commons Attribution-NonCommercial-NoDerivatives 4.0 International License.
	To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-nd/4.0/.
---------------------------------------------------------------------------- */

disableSerialization;

private _vehicleClass = _this;

private _dialog = uiNameSpace getVariable ["RscEsmVehicleRedeemDialog", displayNull];

private _vehicleConfig = configFile >> "CfgVehicles" >> _vehicleClass;

_pin = ctrlText (_dialog displayCtrl const!(IDC_VEHICLE_DIALOG_PIN_EDIT));

private _redeemButton = _dialog displayCtrl const!(IDC_VEHICLE_DIALOG_REDEEM_BUTTON);
_redeemButton ctrlEnable (count(_pin) isEqualTo 4);

// Get the maximum speed, capacity, passengers, armor
private _armor = getNumber(_vehicleConfig >> "armor");
private _fuelCapacity = getNumber(_vehicleConfig >> "fuelCapacity"); // liters
private _maximumLoad = getNumber(_vehicleConfig >> "maximumLoad");
private _maximumSpeed = getNumber(_vehicleConfig >> "maxSpeed");

// Update the stats
private _stats = [
	[
		"Speed",
		format["%1km/h", _maximumSpeed],
		_maximumSpeed / const!(STAT_VEHICLE_SPEED_MAX)
	],
	[
		"Capacity",
		format["%1", _maximumLoad],
		_maximumLoad / const!(STAT_VEHICLE_LOAD_MAX)
	],
	[
		"Armor",
		format["%1", _armor],
		_armor / const!(STAT_VEHICLE_ARMOR_MAX)
	],
	[
		"Fuel Tank",
		format["%1l", _fuelCapacity],
		_fuelCapacity / const!(STAT_VEHICLE_FUEL_MAX)
	]
];

// Then enable the stat bars
private _controlID = const!(IDC_VEHICLE_DIALOG_STAT01_BACKGROUND);

{
	// Background
	(_dialog displayCtrl _controlID) ctrlShow true;

	// Caption
	(_dialog displayCtrl (_controlID + 2)) ctrlSetText (_x select 0);
	(_dialog displayCtrl (_controlID + 2)) ctrlShow true;

	// Label Value
	(_dialog displayCtrl (_controlID + 3)) ctrlSetStructuredText parseText (_x select 1);
	(_dialog displayCtrl (_controlID + 3)) ctrlShow true;

	// Progress
	(_dialog displayCtrl (_controlID + 1)) progressSetPosition (_x select 2);
	(_dialog displayCtrl (_controlID + 1)) ctrlShow true;
	(_dialog displayCtrl (_controlID + 1)) ctrlCommit 1;

	_controlID = _controlID + 4;
}
forEach _stats;

// Update the model
_vehicleClass call ExileClient_gui_modelBox_update;

// Remember the vehicle class
uiNameSpace setVariable ["RscExileVehicleTraderDialogVehicleClass", _vehicleClass];
