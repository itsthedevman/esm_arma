/* ----------------------------------------------------------------------------
Function:
	ESMc_gui_itemRedeemDialog_event_onPlayerInventoryListBoxSelectionChanged

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

disableSerialization;

if !(uiNameSpace getVariable ["RscRedeemDialogIsInitialized", false]) exitWith {};

_listBox = _this select 0;
_index = _this select 1;
_dialog = uiNameSpace getVariable ["RscEsmItemRedeemDialog", displayNull];
_sellButton = _dialog displayCtrl IDC_ITEM_DIALOG_REDEEM_BUTTON;

// If we are waiting for the server to respond, disable the button
if (ExileClientIsWaitingForServerTradeResponse) then
{
	_sellButton ctrlEnable false;
}
else
{
	if (_index > -1) then
	{
		_itemClassName = _listBox lbData _index;

		// If the item is unsalable, deactive the "sell" button
		_sellButton ctrlEnable !(_listBox lbValue _index isEqualTo -1);

		// Deselect store list
		_storeListBox = _dialog displayCtrl IDC_ITEM_DIALOG_STORE_LISTBOX;
		_storeListBox lbSetCurSel -1;
	}
	else
	{
		_sellButton ctrlEnable false;
	};
};

true
