/* ----------------------------------------------------------------------------
Function:
	ESMc_gui_vehicleRedeemDialog_show

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

ExileClientPinCode = "";

// Hide our hud
false call ExileClient_gui_hud_toggle;

// Moon Light adjustment
ExileClientMoonLight setLightBrightness 5;

// Show the dialog
createDialog "RscEsmVehicleRedeemDialog";

private _dialog = uiNameSpace getVariable ["RscEsmVehicleRedeemDialog", displayNull];

// Disable purchase button by default (no vehicle selected)
private _redeemButton = _dialog displayCtrl const!(IDC_VEHICLE_DIALOG_REDEEM_BUTTON);
_redeemButton ctrlEnable false;

// Add the categories to the drop down
private _traderCategories = getArray(
	missionConfigFile >> "CfgTraders" >> ExileClientCurrentTrader >> "categories"
);

// Create the combo boxes
private _categoryComboBox = _dialog displayCtrl const!(IDC_VEHICLE_DIALOG_CATEGORY_DROPDOWN);

// Add the "ALL" Combo
private _allIndex = _categoryComboBox lbAdd "";
_categoryComboBox lbSetCurSel _allIndex;

{
	private _categoryClass = _x;
	private _categoryConfig = missionConfigFile >> "CfgTraderCategories" >> _categoryClass;
	private _categoryIndex = _categoryComboBox lbAdd getText(_categoryConfig >> "name");

	_categoryComboBox lbSetData [_categoryIndex, _categoryClass];
	_categoryComboBox lbSetPicture [_categoryIndex, getText(_categoryConfig >> "icon")];
}
forEach _traderCategories;

// Update the vehicle list
[""] call ESMc_gui_vehicleRedeemDialog_updateVehicleListBox;

// Initialize model box
call ExileClient_gui_modelBox_create;
