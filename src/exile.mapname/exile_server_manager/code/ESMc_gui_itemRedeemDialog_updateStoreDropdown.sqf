_traderConfig = missionConfigFile >> "CfgTraders" >> ExileClientCurrentTrader;
_dialog = uiNameSpace getVariable ["RscExileTraderDialog", displayNull];

// Create the category dropdown
_storeDropdown = _dialog displayCtrl IDC_TRADER_DIALOG_STORE_DROPDOWN;

lbClear _storeDropdown;

_storeDropdown lbAdd "All";
_storeDropdown lbSetData [0, ""];
_storeDropdown lbSetCurSel 0;

{
	_categoryClass = _x;
	_categoryConfig = missionConfigFile >> "CfgTraderCategories" >> _categoryClass;
	_categoryName = getText(_categoryConfig >> "name");
	_categoryIcon = getText(_categoryConfig >> "icon");

	// Fill the combos
	_categoryIndex = _storeDropdown lbAdd _categoryName;
	_storeDropdown lbSetData [_categoryIndex, _categoryClass];
	_categoryComboBox lbSetPicture [_categoryIndex, _categoryIcon];
}
forEach getArray(_traderConfig >> "categories");

true