/* ----------------------------------------------------------------------------
Function:
	ESMc_gui_itemRedeemDialog_event_onStoreListBoxSelectionChanged

Description:
	Fires when the player selects an item from the store

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

private _redeemButton = _dialog displayCtrl const!(IDC_ITEM_DIALOG_REDEEM_BUTTON);
private _quantityDropdown = _dialog displayCtrl const!(IDC_ITEM_DIALOG_QUANTITY_DROPDOWN);
private _inventoryLoadLabel = _dialog displayCtrl const!(IDC_ITEM_DIALOG_PLAYER_LOAD_LABEL);
private _inventoryLoadValue = _dialog displayCtrl const!(IDC_ITEM_DIALOG_PLAYER_LOAD_VALUE);

// Reset the color of the "LOAD" bar to white first (for lazy guys like me)
_inventoryLoadLabel ctrlSetTextColor const!(COLOR_WHITE_ARRAY);
_inventoryLoadValue ctrlSetTextColor const!(COLOR_WHITE_ARRAY);

// Do we have a selection?
if (_index isEqualTo -1) exitWith {};

// Retrieve the item class name
private _itemClassName = _listBox lbData _index;

// Retrieve the inventory container (uniform, vest, backpack, vehicle)
private _inventoryDropdown = _dialog displayCtrl const!(IDC_ITEM_DIALOG_INVENTORY_DROPDOWN);
private _selectedInventoryDropdownIndex = lbCurSel _inventoryDropdown;
private _currentContainerType = _inventoryDropdown lbValue _selectedInventoryDropdownIndex;

private _canRedeemItem = true;
private _tradingResult = const!(TRADING_RESPONSE_OK);

try
{
	private _quality = getNumber(
		missionConfigFile >> "CfgExileArsenal" >> _itemClassName >> "quality"
	);

	private _requiredRespect = getNumber(
		missionConfigFile >> "CfgTrading" >> "requiredRespect" >> format["Level%1",_quality]
	);

	if (_requiredRespect > ExileClientPlayerScore) then
	{
		throw const!(TRADING_RESPONSE_NOT_ENOUGH_RESPECT);
	};

	// It's ensured here that the container exists so no need to test that here
	switch (_currentContainerType) do
	{
		// Player wants to buy the item to the equipment directly (primary weapon etc.)
		case const!(TRADE_CONTAINER_EQUIPMENT):
		{
			_itemInformation = [_itemClassName] call BIS_fnc_itemType;
			_itemType = _itemInformation select 1;

			if !([player, _itemClassName] call ExileClient_util_playerCargo_canAdd) then
			{
				throw const!(TRADING_RESPONSE_NO_SPACE);
			};
		};

		// Player wants to purchase the item to the uniform
		case const!(TRADE_CONTAINER_UNIFORM):
		{
			if !(player canAddItemToUniform _itemClassName) then
			{
				throw const!(TRADING_RESPONSE_NO_SPACE);
			};
		};

		// Player wants to purchase the item into his vest
		case const!(TRADE_CONTAINER_VEST):
		{
			if !(player canAddItemToVest _itemClassName) then
			{
				throw const!(TRADING_RESPONSE_NO_SPACE);
			};
		};

		// "Please store the item in my backpack"
		case const!(TRADE_CONTAINER_BACKPACK):
		{
			if !(player canAddItemToBackpack _itemClassName) then
			{
				throw const!(TRADING_RESPONSE_NO_SPACE);
			};
		};

		// "Drive-in option, add the item to my car"
		default // Vehicle
		{
			private _containerNetID = _inventoryDropdown lbData _selectedInventoryDropdownIndex;
			private _containerVehicle = objectFromNetId _containerNetID;

			// Vehicle doesnt exist? wtf?
			if (_containerVehicle isEqualTo objNull) then
			{
				throw const!(TRADING_RESPONSE_INVALID_CONTAINER);
			};

			if !([_containerVehicle, _itemClassName] call ExileClient_util_containerCargo_canAdd) then
			{
				throw const!(TRADING_RESPONSE_NO_SPACE);
			};
		};
	};
}
catch
{
	_tradingResult = _exception;
	_canRedeemItem = false;
};

// Wait for the server to respond
if (ExileClientIsWaitingForServerTradeResponse) then
{
	_canRedeemItem = false;
};

// The player can buy the item, enable all controls
if (_canRedeemItem) then
{
	_redeemButton ctrlEnable true;
	_quantityDropdown ctrlEnable true;
}
else
{
	// The player cant buy the item, mark the "LOAD" as red to indicate the container is full
	if (_tradingResult isEqualTo const!(TRADING_RESPONSE_NO_SPACE)) then
	{
		_inventoryLoadLabel ctrlSetTextColor const!(COLOR_RED_ARRAY_SUBTLE);
		_inventoryLoadValue ctrlSetTextColor const!(COLOR_RED_ARRAY_SUBTLE);
	};

	// Disable the purchase button
	_redeemButton ctrlEnable false;
	_quantityDropdown ctrlEnable false;
};

// Deselect inventory list
private _inventoryListBox = _dialog displayCtrl const!(IDC_ITEM_DIALOG_INVENTORY_LIST);
_inventoryListBox lbSetCurSel -1;

true
