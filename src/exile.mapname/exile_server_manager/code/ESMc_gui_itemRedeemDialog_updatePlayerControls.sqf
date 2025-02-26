/* ----------------------------------------------------------------------------
Function:
	ESMc_gui_itemRedeemDialog_updatePlayerControls

Description:


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

systemChat "1.1";
disableSerialization;

private _dialog = uiNameSpace getVariable ["RscEsmItemRedeemDialog", displayNull];

// Update player name
private _playerName = _dialog displayCtrl const!(IDC_ITEM_DIALOG_PLAYER_NAME);
_playerName ctrlSetText (toUpper profileName);

// Update player money
private _playerPopTabs = player getVariable ["ExileMoney", 0];
private _popTabsString = _playerPopTabs call ExileClient_util_string_exponentToString;
private _playerMoney = _dialog displayCtrl const!(IDC_ITEM_DIALOG_PLAYER_MONEY);

_playerMoney ctrlSetStructuredText (parseText format[
	"<t size='1' font='puristaMedium' align='right'>%1<img image='\exile_assets\texture\ui\poptab_inline_ca.paa' size='1' shadow='true' /></t>",
	_popTabsString
]);

systemChat "1.2";
true
