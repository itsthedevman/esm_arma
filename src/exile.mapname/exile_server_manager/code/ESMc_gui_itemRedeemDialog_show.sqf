disableSerialization;

ExileClientCurrentTrader = _this getVariable "ExileTraderType";

// Show the dialog
createDialog "RscExileTraderDialog";

// Ensure it is there
waitUntil { !isNull findDisplay IDD_EXILE_TRADER_DIALOG };

_dialog = uiNameSpace getVariable ["RscExileTraderDialog", displayNull];

uiNameSpace setVariable ["RscExileTraderDialogIsInitialized", false];

// Update trader name
_traderName = _dialog displayCtrl IDC_TRADER_DIALOG_TRADER_NAME;
_traderName ctrlSetText getText(missionConfigFile >> "CfgTraders" >> ExileClientCurrentTrader >> "name");

// Move away the focus of the abort button
ctrlSetFocus _traderName;

// If the trader allows filtering for compatible weapon items, show the filter option
_primaryWeaponCheckbox = _dialog displayCtrl IDC_TRADER_DIALOG_PRIMARY_WEAPON_FILTER;
_handgunCheckbox = _dialog displayCtrl IDC_TRADER_DIALOG_HANDGUN_FILTER;
_storeDropdown = _dialog displayCtrl IDC_TRADER_DIALOG_STORE_DROPDOWN;
_storeDropdownSize = ctrlPosition _storeDropdown; // Even if Bohemia named this "position", it seems like this is [x, y, w, h]

if (getNumber (missionConfigFile >> "CfgTraders" >> ExileClientCurrentTrader >> "showWeaponFilter") isEqualTo 1) then
{
	_primaryWeaponCheckbox ctrlShow true;
	_handgunCheckbox ctrlShow true;
	
	// Make it smaller/thinner
	_storeDropdownSize set [2, 13.2 * GUI_GRID_W];
}
else 
{
	_primaryWeaponCheckbox ctrlShow false;
	_handgunCheckbox ctrlShow false;
	
	// Reset to original width
	_storeDropdownSize set [2, 16.5 * GUI_GRID_W];
};

_storeDropdown ctrlSetPosition _storeDropdownSize;
_storeDropdown ctrlCommit 0;
 
// Quantity Dropdown
_quantityDropdown = _dialog displayCtrl IDC_TRADER_DIALOG_QUANTITY_DROPDOWN;
lbClear _quantityDropdown;
_quantityDropdown lbAdd "1x";
_quantityDropdown lbSetCurSel 0;
_quantityDropdown ctrlEnable false;

// Disable things by default
_purchaseButton = _dialog displayCtrl IDC_TRADER_DIALOG_PURCHASE_BUTTON;
_purchaseButton ctrlEnable false;

_sellButton = _dialog displayCtrl IDC_TRADER_DIALOG_SELL_BUTTON;
_sellButton ctrlEnable false;

true call ExileClient_gui_postProcessing_toggleDialogBackgroundBlur;
call ExileClient_gui_traderDialog_updatePlayerControls;
call ExileClient_gui_traderDialog_updateInventoryDropdown;
call ExileClient_gui_traderDialog_updateInventoryListBox;
call ExileClient_gui_traderDialog_updateStoreDropdown;
call ExileClient_gui_traderDialog_updateStoreListBox;
"" call ExileClient_gui_traderDialog_updateItemStats;

uiNameSpace setVariable ["RscExileTraderDialogIsInitialized", true];

true