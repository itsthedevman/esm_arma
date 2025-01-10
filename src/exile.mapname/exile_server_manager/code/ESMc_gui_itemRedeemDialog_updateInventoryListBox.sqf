/* ----------------------------------------------------------------------------
Function:
	ESMc_gui_itemRedeemDialog_updateInventoryListBox

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

private _dialog = uiNameSpace getVariable ["RscEsmItemRedeemDialog", displayNull];

// Get current index
private _inventoryDropdown = _dialog displayCtrl IDC_ITEM_DIALOG_INVENTORY_DROPDOWN;
private _dropdownIndex = lbCurSel _inventoryDropdown;
private _tradeContainerType = _inventoryDropdown lbValue _dropdownIndex;
private _tradeVehicleObject = objNull;

// Inventory List Box
private _inventoryListBox = _dialog displayCtrl IDC_ITEM_DIALOG_INVENTORY_LISTBOX;

lbClear _inventoryListBox;

private _items = [];
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
		_containerClass = getText(
			configFile >> "CfgWeapons" >> (uniform player) >> "ItemInfo" >> "containerClass"
		);

		_maximumLoad = getNumber(configFile >> "CfgVehicles" >> _containerClass >> "maximumLoad");
		_currentLoad = (loadUniform player) * _maximumLoad;
		_items = (uniformContainer player) call ExileClient_util_containerCargo_list;
	};

	case TRADE_CONTAINER_VEST:
	{
		_containerClass = getText(
			configFile >> "CfgWeapons" >> (vest player) >> "ItemInfo" >> "containerClass"
		);

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
private _inventoryLoadProgress = _dialog displayCtrl IDC_ITEM_DIALOG_PLAYER_LOAD_PROGRESS;
_inventoryLoadProgress progressSetPosition (_currentLoad / (_maximumLoad max 1));

private _inventoryLoadValue = _dialog displayCtrl IDC_ITEM_DIALOG_PLAYER_LOAD_VALUE;
_inventoryLoadValue ctrlSetStructuredText (parseText format[
	"<t size='1' font='puristaMedium' align='right'>%1/%2</t>", round(_currentLoad), _maximumLoad
]);

// Update the item list in our inventory
{
	private _itemClassName = _x;
	private _configName = _x call ExileClient_util_gear_getConfigNameByClassName;

	private _quality = getNumber(
		missionConfigFile >> "CfgExileArsenal" >> _itemClassName >> "quality"
	);

	private _sellPrice = _itemClassName call ExileClient_util_gear_calculateSellPrice;
	private _qualityColor = COLOR_QUALITY_LEVEL_1;

	switch (_quality) do
	{
		case QUALITY_LEVEL_2: 		 { _qualityColor = COLOR_QUALITY_LEVEL_2; };
		case QUALITY_LEVEL_3:		 { _qualityColor = COLOR_QUALITY_LEVEL_3; };
		case QUALITY_LEVEL_4:		 { _qualityColor = COLOR_QUALITY_LEVEL_4; };
		case QUALITY_LEVEL_5:		 { _qualityColor = COLOR_QUALITY_LEVEL_5; };
		case QUALITY_LEVEL_6:		 { _qualityColor = COLOR_QUALITY_LEVEL_6; };
	};

	_indexEntryIndex = _inventoryListBox lbAdd getText(
		configFile >> _configName >> _itemClassName >> "displayName"
	);

	_inventoryListBox lbSetData [_indexEntryIndex, _itemClassName];
	_inventoryListBox lbSetColor [_indexEntryIndex, _qualityColor];
	_inventoryListBox lbSetPicture [
		_indexEntryIndex, getText(configFile >> _configName >> _itemClassName >> "picture")
	];
}
forEach _items;

true
