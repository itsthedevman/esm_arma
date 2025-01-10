/* ----------------------------------------------------------------------------
Function:
	ESMc_gui_itemRedeemDialog_event_onStoreDropDownSelectionChanged

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

private _listBox = _this select 0;
private _index = _this select 1;
private _dialog = uiNameSpace getVariable ["RscEsmItemRedeemDialog", displayNull];

// Cannot buy anything, because no selection
private _storeListBox = _dialog displayCtrl IDC_ITEM_DIALOG_STORE_LISTBOX;
_storeListBox lbSetCurSel -1;

private _inventoryListBox = _dialog displayCtrl IDC_ITEM_DIALOG_INVENTORY_LISTBOX;
_inventoryListBox lbSetCurSel -1;

call ESMc_gui_itemRedeemDialog_updateStoreListBox;

true
