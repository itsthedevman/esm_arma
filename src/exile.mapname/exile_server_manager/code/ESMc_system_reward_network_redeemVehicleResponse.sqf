/* ----------------------------------------------------------------------------
Function:
	ESMc_system_reward_network_redeemVehicleResponse

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

private _responseCode = _this select 0;
private _vehicleNetID = _this select 1;

ExileClientIsWaitingForServerTradeResponse = false;

if (_responseCode isNotEqualTo const!(TRADING_RESPONSE_OK)) exitWith
{
	[
		"ErrorTitleAndText",
		[
			"Whoops!",
			format [
				"Something went really wrong. Please tell a server admin that you have tried to redeem a vehicle and tell them the code '%1'. Thank you!",
				_responseCode
			]
		]
	] call ExileClient_gui_toaster_addTemplateToast;
};

private _vehicleObject = objectFromNetId _vehicleNetID;

// Move in as driver!
player moveInDriver _vehicleObject;

// Show notification
["SuccessTitleOnly", ["Vehicle redeemed!"]] call ExileClient_gui_toaster_addTemplateToast;

true
