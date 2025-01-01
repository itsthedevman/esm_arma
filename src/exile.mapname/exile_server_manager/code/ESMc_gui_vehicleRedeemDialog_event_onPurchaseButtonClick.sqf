/*
	Ask server to buy the vehicle
*/

_vehicleClass = uiNameSpace getVariable ["RscExileVehicleTraderDialogVehicleClass", ""];
_salesPrice = getNumber(missionConfigFile >> "CfgExileArsenal" >> _vehicleClass >> "price");
_quality = getNumber(missionConfigFile >> "CfgExileArsenal" >> _vehicleClass >> "quality");
_requiredRespect = getNumber(missionConfigFile >> "CfgTrading" >> "requiredRespect" >> format["Level%1",_quality]);
_pin = ctrlText ((uiNamespace getVariable ["RscExileVehicleTraderDialog",displayNull]) displayCtrl IDC_VEHICLE_TRADER_DIALOG_PIN_EDIT);

closeDialog 0;

if (count _pin != 4) exitWith {
	["ErrorTitleAndText", ["Vehicle Purchase Aborted", "Pin not 4 characters."]] call ExileClient_gui_toaster_addTemplateToast;
};

if (_salesPrice > (player getVariable ["ExileMoney", 0])) exitWith {
	["ErrorTitleAndText", ["Vehicle Purchase Aborted", "Not enought money."]] call ExileClient_gui_toaster_addTemplateToast;
};

if (_requiredRespect > ExileClientPlayerScore) exitWith {
	["ErrorTitleAndText", ["Vehicle Purchase Aborted", "Not enought respect."]] call ExileClient_gui_toaster_addTemplateToast;
};

if(ExileClientIsWaitingForServerTradeResponse)exitWith{
	["ErrorTitleAndText", ["Vehicle Purchase Aborted", "The Trader is busy."]] call ExileClient_gui_toaster_addTemplateToast;
};

ExileClientIsWaitingForServerTradeResponse = true;

["purchaseVehicleRequest", [_vehicleClass,_pin]] call ExileClient_system_network_send;
