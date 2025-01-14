/* ----------------------------------------------------------------------------
Function:
	ESMc_gui_itemRedeemDialog_updateStoreListBox

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

if !(uiNameSpace getVariable ["RscRedeemDialogIsInitialized", false]) exitWith {};

private _dialog = uiNameSpace getVariable ["RscEsmItemRedeemDialog", displayNull];

private _categoryDropdown = _dialog displayCtrl IDC_ITEM_DIALOG_STORE_DROPDOWN;
private _currentCategoryIndex = lbCurSel _categoryDropdown;
private _currentCategory = _categoryDropdown lbData _currentCategoryIndex;

private _storeListBox = _dialog displayCtrl IDC_ITEM_DIALOG_STORE_LISTBOX;
lbClear _storeListBox;

private _traderConfig = missionConfigFile >> "CfgTraders" >> ExileClientCurrentTrader;

// Check if we filter for items that are compatible to our primary weapon
_applyItemClassFilter = false;
_filterToItemClasses = [];

// If the player has a primary weapon equipped, allow filtering
if !((primaryWeapon player) isEqualTo "") then
{
	_primaryWeaponCheckbox = _dialog displayCtrl IDC_ITEM_DIALOG_PRIMARY_WEAPON_FILTER;

	// If the checkbox is checked, proceed
	if (cbChecked _primaryWeaponCheckbox) then
	{
		_applyItemClassFilter = true;
		_filterToItemClasses append ((primaryWeapon player) call ExileClient_util_item_getCompatibleWeaponItems);
	};
};

// Check if we filter for items that are compatible to our handgun (BOOM!)
if !((handgunWeapon player) isEqualTo "") then
{
	_handgunCheckbox = _dialog displayCtrl IDC_ITEM_DIALOG_HANDGUN_FILTER;

	// If the checkbox is checked, proceed
	if (cbChecked _handgunCheckbox) then
	{
		_applyItemClassFilter = true;
		_filterToItemClasses append ((handgunWeapon player) call ExileClient_util_item_getCompatibleWeaponItems);
	};
};

{
	_categoryClass = _x;

	if (_currentCategoryIndex isEqualTo 0 || _currentCategory isEqualTo _categoryClass) then
	{
		_categoryItemClassNames = getArray(missionConfigFile >> "CfgTraderCategories" >> _categoryClass >> "items");

		// Add the items
		{
			_itemClassName = _x;

			// Apply filtering to our list box
			_showItem = true;

			// If filtering is enabled, only show items that are not filtered
			if (_applyItemClassFilter) then
			{
				_showItem = _itemClassName in _filterToItemClasses;
			};

			if (_showItem) then
			{
				_configName = _x call ExileClient_util_gear_getConfigNameByClassName;

				_indexEntryIndex = _storeListBox lbAdd getText(configFile >> _configName >> _itemClassName >> "displayName");
				_quality = getNumber(missionConfigFile >> "CfgExileArsenal" >> _itemClassName >> "quality");
				_salesPrice = getNumber(missionConfigFile >> "CfgExileArsenal" >> _itemClassName >> "price");
				_requiredRespect = getNumber(missionConfigFile >> "CfgTrading" >> "requiredRespect" >> format["Level%1",_quality]);
				_qualityColor = COLOR_QUALITY_LEVEL_1;
				_popTabColor = COLOR_WHITE_ARRAY;
				_imageColor = COLOR_WHITE_ARRAY;

				switch (_quality) do
				{
					case QUALITY_LEVEL_2: 		 { _qualityColor = COLOR_QUALITY_LEVEL_2; };
					case QUALITY_LEVEL_3:		 { _qualityColor = COLOR_QUALITY_LEVEL_3; };
					case QUALITY_LEVEL_4:		 { _qualityColor = COLOR_QUALITY_LEVEL_4; };
					case QUALITY_LEVEL_5:		 { _qualityColor = COLOR_QUALITY_LEVEL_5; };
					case QUALITY_LEVEL_6:		 { _qualityColor = COLOR_QUALITY_LEVEL_6; };
				};

				_playerMoney = player getVariable ["ExileMoney", 0];

				// If the player cant afford the item, mark the price in dark red
		    	if (_salesPrice > _playerMoney) then
	    		{
	    			_popTabColor = COLOR_RED_ARRAY_SUBTLE;
	    			_missingPopTabs = _salesPrice - _playerMoney;
	    			_storeListBox lbSetTooltip [_indexEntryIndex, format["Missing %1 Pop Tabs", _missingPopTabs call ExileClient_util_string_exponentToString]];
	    		};

				// If the player doesn't have enough respect, set the item name to 50% transparency
	    		if (_requiredRespect > ExileClientPlayerScore) then
	    		{
	    			_qualityColor set [3, 0.3];
	    			_popTabColor set [3, 0.3];
	    			_imageColor set [3, 0.3];
	    			_missingRespect = _requiredRespect - ExileClientPlayerScore;
	    			_storeListBox lbSetTooltip [_indexEntryIndex, format["Missing %1 Respect", _missingRespect]];
	    		};

	    		// If missing both Pop Tabs & Respsect change tooltip
	    		if ((_salesPrice > _playerMoney) && (_requiredRespect > ExileClientPlayerScore)) then
	    		{
					_storeListBox lbSetTooltip [_indexEntryIndex, format["Missing %1 Pop Tabs & %2 Respect", _missingPopTabs call ExileClient_util_string_exponentToString, _missingRespect]];
		    	};

				_storeListBox lbSetData [_indexEntryIndex, _itemClassName];
				_storeListBox lbSetColor [_indexEntryIndex, _qualityColor];
		    	_storeListBox lbSetPicture [_indexEntryIndex, getText(configFile >> _configName >> _itemClassName >> "picture")];
		    	_storeListBox lbSetPictureColor [_indexEntryIndex, _imageColor];
		    	_storeListBox lbSetTextRight [_indexEntryIndex, _salesPrice call ExileClient_util_string_exponentToString];
		    	_storeListBox lbSetColorRight [_indexEntryIndex, _popTabColor];
		    	_storeListBox lbSetPictureRight [_indexEntryIndex, "exile_assets\texture\ui\poptab_trader_ca.paa"];
		    	_storeListBox lbSetPictureRightColor [_indexEntryIndex, _popTabColor];
				_storeListBox lbSetValue [_indexEntryIndex, _quality * 100000 + _salesPrice];
    		};
		}
		forEach _categoryItemClassNames;
	};
}
forEach getArray(_traderConfig >> "categories");

lbSortByValue _storeListBox;

true
