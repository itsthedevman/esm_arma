disableSerialization;

_dialog = uiNameSpace getVariable ["RscExileTraderDialog", displayNull];

// Get current index
_inventoryDropdown = _dialog displayCtrl IDC_TRADER_DIALOG_INVENTORY_DROPDOWN;
_dropdownIndex = lbCurSel _inventoryDropdown;
_tradeContainerType = _inventoryDropdown lbValue _dropdownIndex;
_tradeVehicleObject = objNull;

// Inventory List Box
_inventoryListBox = _dialog displayCtrl IDC_TRADER_DIALOG_INVENTORY_LISTBOX;

lbClear _inventoryListBox;

switch (_tradeContainerType) do
{
	case TRADE_CONTAINER_EQUIPMENT: 
	{
		_currentLoad = (loadAbs player);
		_maximumLoad = getNumber(configfile >> "CfgInventoryGlobalVariable" >> "maxSoldierLoad");
		_items = [player, true] call ExileClient_util_playerEquipment_list;
	};

	case TRADE_CONTAINER_UNIFORM:
	{
		_containerClass = getText(configFile >> "CfgWeapons" >> (uniform player) >> "ItemInfo" >> "containerClass");
		_maximumLoad = getNumber(configFile >> "CfgVehicles" >> _containerClass >> "maximumLoad");
		_currentLoad = (loadUniform player) * _maximumLoad;
		_items = (uniformContainer player) call ExileClient_util_containerCargo_list;
	};

	case TRADE_CONTAINER_VEST: 
	{
		_containerClass = getText(configFile >> "CfgWeapons" >> (vest player) >> "ItemInfo" >> "containerClass");
		_maximumLoad = getNumber(configFile >> "CfgVehicles" >> _containerClass >> "maximumLoad");
		_currentLoad = (loadVest player) * _maximumLoad;
		_items = (vestContainer player) call ExileClient_util_containerCargo_list;
	};

	case TRADE_CONTAINER_BACKPACK:
	{
		_maximumLoad = getNumber(configFile >> "CfgVehicles" >> (backpack player) >> "maximumLoad");
		_currentLoad = (loadBackpack player) * _maximumLoad;
		_items = (backpackContainer player) call ExileClient_util_containerCargo_list;
	};

	default // TRADE_CONTAINER_VEHICLE
	{
		_tradeVehicleNetID = _inventoryDropdown lbData _dropdownIndex;
		_tradeVehicleObject = objectFromNetId _tradeVehicleNetID;

		_maximumLoad = getNumber(configFile >> "CfgVehicles" >> (typeOf _tradeVehicleObject) >> "maximumLoad");
		_items = _tradeVehicleObject call ExileClient_util_containerCargo_list;
		_currentLoad = _items call ExileClient_util_gear_calculateLoad;
	};
};

// Update player load
_inventoryLoadProgress = _dialog displayCtrl IDC_TRADER_DIALOG_PLAYER_LOAD_PROGRESS;
_inventoryLoadProgress progressSetPosition (_currentLoad / (_maximumLoad max 1));

_inventoryLoadValue = _dialog displayCtrl IDC_TRADER_DIALOG_PLAYER_LOAD_VALUE;
_inventoryLoadValue ctrlSetStructuredText (parseText format["<t size='1' font='puristaMedium' align='right'>%1/%2</t>", round(_currentLoad), _maximumLoad]);

// Update the item list in our inventory
{
	_itemClassName = _x;
	_configName = _x call ExileClient_util_gear_getConfigNameByClassName;

	_quality = getNumber(missionConfigFile >> "CfgExileArsenal" >> _itemClassName >> "quality");
	_sellPrice = _itemClassName call ExileClient_util_gear_calculateSellPrice;
	_qualityColor = COLOR_QUALITY_LEVEL_1;

	// TODO: If this is a magazine, lower the price by the % of bullets remaining?

	switch (_quality) do
	{
		case QUALITY_LEVEL_2: 		 { _qualityColor = COLOR_QUALITY_LEVEL_2; };
		case QUALITY_LEVEL_3:		 { _qualityColor = COLOR_QUALITY_LEVEL_3; };
		case QUALITY_LEVEL_4:		 { _qualityColor = COLOR_QUALITY_LEVEL_4; };
		case QUALITY_LEVEL_5:		 { _qualityColor = COLOR_QUALITY_LEVEL_5; };
		case QUALITY_LEVEL_6:		 { _qualityColor = COLOR_QUALITY_LEVEL_6; };						
	};

	_indexEntryIndex = _inventoryListBox lbAdd getText(configFile >> _configName >> _itemClassName >> "displayName");
	_inventoryListBox lbSetData [_indexEntryIndex, _itemClassName];
	_inventoryListBox lbSetColor [_indexEntryIndex, _qualityColor];
	_inventoryListBox lbSetPicture [_indexEntryIndex, getText(configFile >> _configName >> _itemClassName >> "picture")];

	// If this is the equipment, you can only sell containers when they are empty
	_canSellItem = true;

	if (_tradeContainerType isEqualTo TRADE_CONTAINER_EQUIPMENT) then
	{
		scopeName "OUTER";

		{
			_containerClassName = _x select 0;
			_containerContainer = _x select 1;

			if (_itemClassName isEqualTo _containerClassName) then
			{
				_itemsInContainer = _containerContainer call ExileClient_util_containerCargo_list;

				if !((count _itemsInContainer) isEqualTo 0) then
				{
					_canSellItem = false;
					breakTo "OUTER";
				};
			};
		}
		forEach 
		[
			[uniform player, uniformContainer player], 
			[vest player, vestContainer player], 
			[backpack player, backpackContainer player]
		];

		// If this is an equipped weapon and that weapon has attachments, then add
		// the sales price of the weapon for more profit <3
		if (_itemClassName isEqualTo (primaryWeapon player)) then
		{
			{
				{
					if !(_x isEqualTo "") then
					{
						_sellPrice = _sellPrice + (_x call ExileClient_util_gear_calculateSellPrice);
					};
				}
				forEach _x;
			}
			forEach 
			[
				primaryWeaponItems player,
				primaryWeaponMagazine player
			];
		};

		// Same for pistols
		if (_itemClassName isEqualTo (handgunWeapon player)) then
		{
			{
				{
					if !(_x isEqualTo "") then
					{
						_sellPrice = _sellPrice + (_x call ExileClient_util_gear_calculateSellPrice);
					};
				}
				forEach _x;
			}
			forEach 
			[
				handgunItems player,
				handgunMagazine player
			];
		};
	};

	// If it cannot be sold, dont show the price
	if (_canSellItem) then
	{
		// Only show if the sell price is greater than 0 OR we are in escape mode and the price is greater/equal 0
    	if (_sellPrice > 0 || ((getText(missionConfigFile >> "Header" >> "gameType") isEqualTo "Escape") && {_sellPrice >= 0})) then
    	{
    		_inventoryListBox lbSetValue [_indexEntryIndex, _sellPrice];
	    	_inventoryListBox lbSetTextRight [_indexEntryIndex, format["%1", _sellPrice]];
	    	_inventoryListBox lbSetPictureRight [_indexEntryIndex, "exile_assets\texture\ui\poptab_trader_ca.paa"];
    	}
    	else 
    	{
    		_inventoryListBox lbSetValue [_indexEntryIndex, -1];
    		_inventoryListBox lbSetColorRight [_indexEntryIndex, [0.5, 0.5, 0.5, 1]];
    		_inventoryListBox lbSetTextRight [_indexEntryIndex, "(unsaleable)"];	
    	};
	}
	else 
	{
		_inventoryListBox lbSetValue [_indexEntryIndex, -1];
		_inventoryListBox lbSetColorRight [_indexEntryIndex, [0.5, 0.5, 0.5, 1]];
		_inventoryListBox lbSetTextRight [_indexEntryIndex, "(not empty)"];	
	};
}
forEach _items;

true