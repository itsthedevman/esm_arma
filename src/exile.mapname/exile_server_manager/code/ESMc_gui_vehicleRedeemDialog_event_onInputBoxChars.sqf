/* 
/	WORST CODE EVER!
/	I HATE IT
*/

disableSerialization;

_inputBox = _this select 0;
_character = _this select 1;

_dialog = uiNameSpace getVariable ["RscExileVehicleTraderDialog", displayNull];
_purchaseButton = _dialog displayCtrl IDC_VEHICLE_TRADER_DIALOG_PURCHASE_BUTTON;
_vehicleClass = uiNamespace getVariable ["RscExileVehicleTraderDialogVehicleClass",""];
_salesPrice = getNumber(missionConfigFile >> "CfgExileArsenal" >> _vehicleClass >> "price");
_quality = getNumber(missionConfigFile >> "CfgExileArsenal" >> _vehicleClass >> "quality");
_requiredRespect = getNumber(missionConfigFile >> "CfgTrading" >> "requiredRespect" >> format["Level%1",_quality]);

_ctrlText = (ctrlText _inputBox);

// Throw false if it cant be bought
try 
{
	// If the player does not have enough respect, he cannot buy it
	if (_requiredRespect > ExileClientPlayerScore) then
	{
		throw false;
	};

	// If the player is too poor, he cannot buy it
	if (_salesPrice > (player getVariable ["ExileMoney", 0])) then 
	{
		throw false;
	};

	// If it is not exactly 4 digits, cancel
	if !((count _ctrlText) isEqualTo 4) then
	{
		throw false;
	};

	// Check all for characters and cancel if its not four digits
	{
		if !(_x in [48, 49, 50, 51, 52, 53, 54, 55, 56, 57]) then
		{
			throw false;
		};
	}
	forEach (toArray _ctrlText);

	// Enable the purchase button, if we can effort it
	_purchaseButton ctrlEnable true;
}
catch 
{
	_purchaseButton ctrlEnable false;
};

// If the entered character is not a digit, remove it
if !(_character in [48,49,50,51,52,53,54,55,56,57]) then
{
	_ctrlText = _ctrlText select [0, (count _ctrlText) - 1];
	_inputBox ctrlSetText _ctrlText;
	_inputBox ctrlCommit 0;
};

true