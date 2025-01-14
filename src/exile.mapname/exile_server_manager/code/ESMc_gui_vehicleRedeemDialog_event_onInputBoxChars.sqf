/* ----------------------------------------------------------------------------
Function:
	ESMc_gui_vehicleRedeemDialog_event_onInputBoxChars

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

private _inputBox = _this select 0;
private _character = _this select 1;

private _dialog = uiNameSpace getVariable ["RscExileVehicleTraderDialog", displayNull];

private _redeemButton = _dialog displayCtrl IDC_VEHICLE_TRADER_DIALOG_PURCHASE_BUTTON;

private _vehicleClass = uiNamespace getVariable ["RscExileVehicleTraderDialogVehicleClass", ""];
private _quality = getNumber(missionConfigFile >> "CfgExileArsenal" >> _vehicleClass >> "quality");

private _ctrlText = (ctrlText _inputBox);
private _allowedChars = [48, 49, 50, 51, 52, 53, 54, 55, 56, 57];

// Throw false if it cant be bought
try
{
	// If it is not exactly 4 digits, cancel
	if !((count _ctrlText) isEqualTo 4) then
	{
		throw false;
	};

	// Check all for characters and cancel if its not four digits
	{
		if !(_x in _allowedChars) then
		{
			throw false;
		};
	}
	forEach (toArray _ctrlText);

	// Enable the redeem button
	_redeemButton ctrlEnable true;
}
catch
{
	_redeemButton ctrlEnable false;
};

// If the entered character is not a digit, remove it
if !(_character in _allowedChars) then
{
	private _ctrlText = _ctrlText select [0, (count _ctrlText) - 1];
	_inputBox ctrlSetText _ctrlText;
	_inputBox ctrlCommit 0;
};

true
