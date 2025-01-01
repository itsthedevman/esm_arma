disableSerialization;

_traderObject = _this;

ExileClientCurrentTrader = _this getVariable "ExileTraderType";

ExileClientPinCode = "";

// Background blur
//ExileClientPostProcessingBackgroundBlur ppEffectAdjust [2];
//ExileClientPostProcessingBackgroundBlur ppEffectEnable true;
//ExileClientPostProcessingBackgroundBlur ppEffectCommit 1;

// Hide our hud
false call ExileClient_gui_hud_toggle;

// Moon Light adjustment
ExileClientMoonLight setLightBrightness 5;

// Show the dialog
createDialog "RscExileVehicleTraderDialog";

_dialog = uiNameSpace getVariable ["RscExileVehicleTraderDialog", displayNull];

// Disable purchase button by default (no vehicle selected)
_purchaseButton = _dialog displayCtrl IDC_VEHICLE_TRADER_DIALOG_PURCHASE_BUTTON;
_purchaseButton ctrlEnable false;


// Add the categories to the drop down
_traderCategories = getArray(missionConfigFile >> "CfgTraders" >> ExileClientCurrentTrader >> "categories");

// Create the combo boxes
_categoryComboBox = _dialog displayCtrl IDC_VEHICLE_TRADER_DIALOG_CATEGORY_DROPDOWN;

// Add the "ALL" Combo
_allIndex = _categoryComboBox lbAdd "";
_categoryComboBox lbSetCurSel _allIndex;

{
	_categoryClass = _x;
	_categoryConfig = missionConfigFile >> "CfgTraderCategories" >> _categoryClass;
	_categoryIndex = _categoryComboBox lbAdd getText(_categoryConfig >> "name");
	_categoryComboBox lbSetData [_categoryIndex, _categoryClass];
	_categoryComboBox lbSetPicture [_categoryIndex, getText(_categoryConfig >> "icon")];
}
forEach _traderCategories;

// Update the vehicle list
[""] call ExileClient_gui_vehicleTraderDialog_updateVehicleListBox;

// Initialize model box
call ExileClient_gui_modelBox_create;