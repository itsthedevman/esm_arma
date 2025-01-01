disableSerialization;

_dialog = uiNameSpace getVariable ["RscExileVehicleTraderDialog", displayNull];
_categoryClasses = _this;

if (_categoryClasses select 0 == "") then
{
	_categoryClasses = getArray(missionConfigFile >> "CfgTraders" >> ExileClientCurrentTrader >> "categories");
};

// Clear the list before
_itemListControl = _dialog displayCtrl IDC_VEHICLE_TRADER_DIALOG_VEHICLE_LIST;

lbClear _itemListControl;

{
	_categoryClass = _x;
	_categoryVehicleClassNames = getArray(missionConfigFile >> "CfgTraderCategories" >> _categoryClass >> "items");

	// Add the vehicles
	{
		_className = _x;
		_salesPrice = getNumber(missionConfigFile >> "CfgExileArsenal" >> _className >> "price");
		_indexEntryIndex = _itemListControl lbAdd getText(configFile >> "CfgVehicles" >> _className >> "displayName");
		_playerMoney = player getVariable ["ExileMoney", 0];
		_quality = getNumber(missionConfigFile >> "CfgExileArsenal" >> _className >> "quality");
		_requiredRespect = getNumber(missionConfigFile >> "CfgTrading" >> "requiredRespect" >> format["Level%1",_quality]);
		_qualityColor = COLOR_QUALITY_LEVEL_1;
		_popTabColor = COLOR_WHITE_ARRAY;

		switch (_quality) do
		{
			case QUALITY_LEVEL_2: 		 { _qualityColor = COLOR_QUALITY_LEVEL_2; };
			case QUALITY_LEVEL_3:		 { _qualityColor = COLOR_QUALITY_LEVEL_3; };
			case QUALITY_LEVEL_4:		 { _qualityColor = COLOR_QUALITY_LEVEL_4; };
			case QUALITY_LEVEL_5:		 { _qualityColor = COLOR_QUALITY_LEVEL_5; };
			case QUALITY_LEVEL_6:		 { _qualityColor = COLOR_QUALITY_LEVEL_6; };
		};

		// If the player cant afford the item, mark the price in dark red
		if (_salesPrice > _playerMoney) then
		{
			_popTabColor = COLOR_RED_ARRAY_SUBTLE;
			_missingPopTabs = _salesPrice - _playerMoney;
			_itemListControl lbSetTooltip [_indexEntryIndex, format["Missing %1 Pop Tabs", _missingPopTabs call ExileClient_util_string_exponentToString]];
		};

		// If the player doesn't have enough respect, set the item name to 50% transparency
		if (_requiredRespect > ExileClientPlayerScore) then
		{
			_qualityColor set [3, 0.3];
			_popTabColor set [3, 0.3];
			_missingRespect = _requiredRespect - ExileClientPlayerScore;
			_itemListControl lbSetTooltip [_indexEntryIndex, format["Missing %1 Respect", _missingRespect]];
		};

		// If missing both Pop Tabs & Respsect change tooltip
		if ((_salesPrice > _playerMoney) && (_requiredRespect > ExileClientPlayerScore)) then
		{
			_itemListControl lbSetTooltip [_indexEntryIndex, format["Missing %1 Pop Tabs & %2 Respect", _missingPopTabs call ExileClient_util_string_exponentToString, _missingRespect]];
		};

		_itemListControl lbSetData [_indexEntryIndex, _className];
    	_itemListControl lbSetTextRight [_indexEntryIndex, _salesPrice call ExileClient_util_string_exponentToString];
    	_itemListControl lbSetPictureRight [_indexEntryIndex, "exile_assets\texture\ui\poptab_trader_ca.paa"];
		_itemListControl lbSetColor [_indexEntryIndex, _qualityColor];
		_itemListControl lbSetColorRight [_indexEntryIndex, _popTabColor];
		_itemListControl lbSetPictureRightColor [_indexEntryIndex, _popTabColor];
		_itemListControl lbSetValue [_indexEntryIndex, _quality * 100000 + _salesPrice];
	}
	forEach _categoryVehicleClassNames;
}
forEach _categoryClasses;

lbSortByValue _itemListControl;

true
