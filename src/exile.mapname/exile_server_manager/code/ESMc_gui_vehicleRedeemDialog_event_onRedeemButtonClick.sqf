/* ----------------------------------------------------------------------------
Function:
	ESMc_gui_vehicleRedeemDialog_event_onRedeemButtonClick

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

private _vehicleClass = uiNameSpace getVariable ["RscExileVehicleTraderDialogVehicleClass", ""];

private _display = uiNamespace getVariable ["RscEsmVehicleRedeemDialog", displayNull];
private _pin = ctrlText (_display displayCtrl IDC_VEHICLE_TRADER_DIALOG_PIN_EDIT);

closeDialog 0;

try
{
	if (count _pin != 4) then
	{
		throw "Pin not 4 characters";
	};

	if (ExileClientIsWaitingForServerTradeResponse) then
	{
		throw "The trader is busy";
	};

	ExileClientIsWaitingForServerTradeResponse = true;

	["redeemVehicleRequest", [_rewardCode, _pin]] call ExileClient_system_network_send;
}
catch
{
	[
		"ErrorTitleAndText",
		["Vehicle Purchase Aborted", _exception]
	] call ExileClient_gui_toaster_addTemplateToast;
};
