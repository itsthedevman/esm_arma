disableSerialization;

_vehicleClass = _this;
_dialog = uiNameSpace getVariable ["RscExileVehicleTraderDialog", displayNull];
_traderObject = uiNameSpace getVariable ["ExileCurrentTrader", objNull];
_vehicleConfig = configFile >> "CfgVehicles" >> _vehicleClass;

// Disable the purchase button if not effordable
_salesPrice = getNumber(missionConfigFile >> "CfgExileArsenal" >> _vehicleClass >> "price");

_pin = ctrlText (_dialog displayCtrl IDC_VEHICLE_TRADER_DIALOG_PIN_EDIT);

if(count _pin isEqualTo 4)then
{
	_quality = getNumber(missionConfigFile >> "CfgExileArsenal" >> _vehicleClass >> "quality");
	_requiredRespect = getNumber(missionConfigFile >> "CfgTrading" >> "requiredRespect" >> format["Level%1",_quality]);
	_purchaseButton = _dialog displayCtrl IDC_VEHICLE_TRADER_DIALOG_PURCHASE_BUTTON;

	if(_requiredRespect <= ExileClientPlayerScore)then
	{
		_purchaseButton ctrlEnable (_salesPrice <= (player getVariable ["ExileMoney", 0]));
	}
	else
	{
		_purchaseButton ctrlEnable false;
	};
};

// Get the maximum speed, capacity, passengers, armor
_armor = getNumber(_vehicleConfig >> "armor");
_fuelCapacity = getNumber(_vehicleConfig >> "fuelCapacity"); // liters
_maximumLoad = getNumber(_vehicleConfig >> "maximumLoad");
_maximumSpeed = getNumber(_vehicleConfig >> "maxSpeed");

// Update the stats
_stats = [];
_stats pushBack ["Speed", 		format["%1km/h", 	_maximumSpeed], 	_maximumSpeed/STAT_VEHICLE_SPEED_MAX 	];
_stats pushBack ["Capacity", 	format["%1", 		_maximumLoad], 		_maximumLoad/STAT_VEHICLE_LOAD_MAX 		];
_stats pushBack ["Armor", 		format["%1", 		_armor], 			_armor/STAT_VEHICLE_ARMOR_MAX 			];
_stats pushBack ["Fuel Tank", 	format["%1l", 		_fuelCapacity], 	_fuelCapacity/STAT_VEHICLE_FUEL_MAX 	];

// Then enable the stat bars
_controlID = IDC_VEHICLE_TRADER_STAT01_BACKGROUND;

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