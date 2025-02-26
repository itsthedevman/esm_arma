/* ----------------------------------------------------------------------------
Function:
	ESMc_gui_itemRedeemDialog_updateStoreDropdown

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

systemChat "4.1";
private _dialog = uiNameSpace getVariable ["RscEsmItemRedeemDialog", displayNull];

// Create the category dropdown
private _storeDropdown = _dialog displayCtrl const!(IDC_ITEM_DIALOG_STORE_DROPDOWN);

lbClear _storeDropdown;

_storeDropdown lbAdd "All";
_storeDropdown lbSetData [0, ""];
_storeDropdown lbSetCurSel 0;

{
	private _categoryClass = _x;
	private _categoryConfig = missionConfigFile >> "CfgTraderCategories" >> _categoryClass;
	private _categoryName = getText(_categoryConfig >> "name");
	private _categoryIcon = getText(_categoryConfig >> "icon");

	// Fill the combos
	private _categoryIndex = _storeDropdown lbAdd _categoryName;

	_storeDropdown lbSetData [_categoryIndex, _categoryClass];
	// _categoryComboBox lbSetPicture [_categoryIndex, _categoryIcon];
}
forEach [];

systemChat "4.2";
true
