/*
	Fires when the player selects an item from the store

	IMPROVE: Highlight magazines/scopes/bipods/pointers/silencers that fit to our primary weapon
*/

disableSerialization;

if !(uiNameSpace getVariable ["RscExileTraderDialogIsInitialized", false]) exitWith {};

_listBox = _this select 0;
_index = _this select 1;
_dialog = uiNameSpace getVariable ["RscExileTraderDialog", displayNull];
_purchaseButton = _dialog displayCtrl IDC_TRADER_DIALOG_PURCHASE_BUTTON;
_quantityDropdown = _dialog displayCtrl IDC_TRADER_DIALOG_QUANTITY_DROPDOWN;
_inventoryLoadLabel = _dialog displayCtrl IDC_TRADER_DIALOG_PLAYER_LOAD_LABEL;
_inventoryLoadValue = _dialog displayCtrl IDC_TRADER_DIALOG_PLAYER_LOAD_VALUE;

// Reset the color of the "LOAD" bar to white first (for lazy guys like me)
_inventoryLoadLabel ctrlSetTextColor COLOR_WHITE_ARRAY;
_inventoryLoadValue ctrlSetTextColor COLOR_WHITE_ARRAY;

// Do we have a selection?
if (_index > -1) then
{
	// Retrieve the item class name
	_itemClassName = _listBox lbData _index;
	_itemClassName call ExileClient_gui_traderDialog_updateItemStats;

	// Retrieve the inventory container (uniform, vest, backpack, vehicle)
	_inventoryDropdown = _dialog displayCtrl IDC_TRADER_DIALOG_INVENTORY_DROPDOWN;
	_selectedInventoryDropdownIndex = lbCurSel _inventoryDropdown;
	_currentContainerType = _inventoryDropdown lbValue _selectedInventoryDropdownIndex;
	_canBuyItem = true;
	_tradingResult = TRADING_RESPONSE_OK;

	try 
	{
		// Check if we can afford the item
		_salesPrice = getNumber(missionConfigFile >> "CfgExileArsenal" >> _itemClassName >> "price");

		if (_salesPrice > (player getVariable ["ExileMoney", 0])) then 
		{
			throw TRADING_RESPONSE_POOR_PLAYER;
		};

		_quality = getNumber(missionConfigFile >> "CfgExileArsenal" >> _itemClassName >> "quality");
		_requiredRespect = getNumber(missionConfigFile >> "CfgTrading" >> "requiredRespect" >> format["Level%1",_quality]);

		if (_requiredRespect > ExileClientPlayerScore) then
		{
			throw TRADING_RESPONSE_NOT_ENOUGH_RESPECT;
		};

		// (Its ensured here, that the container exists, so no need to test that here)
		switch (_currentContainerType) do
		{
			// Player wants to buy the item to the equipment directly (primary weapon etc.)
			case TRADE_CONTAINER_EQUIPMENT:
			{
				_itemInformation = [_itemClassName] call BIS_fnc_itemType;
				_itemType = _itemInformation select 1;

				if !([player, _itemClassName] call ExileClient_util_playerCargo_canAdd) then
				{
					throw TRADING_RESPONSE_NO_SPACE;
				};
			};

			// Player wants to purchase the item to the uniform
			case TRADE_CONTAINER_UNIFORM:
			{	
				if !(player canAddItemToUniform _itemClassName) then 
				{
					throw TRADING_RESPONSE_NO_SPACE;
				};
			};

			// Player wants to purchase the item into his vest
			case TRADE_CONTAINER_VEST:
			{
				if !(player canAddItemToVest _itemClassName) then 
				{
					throw TRADING_RESPONSE_NO_SPACE;
				};
			};

			// "Please store the item in my backpack"
			case TRADE_CONTAINER_BACKPACK:
			{
				if !(player canAddItemToBackpack _itemClassName) then 
				{
					throw TRADING_RESPONSE_NO_SPACE;
				};
			};

			// "Drive-in option, add the item to my car"
			default // Vehicle
			{
				_containerNetID = _inventoryDropdown lbData _selectedInventoryDropdownIndex;
				_containerVehicle = objectFromNetId _containerNetID;

				// Vehicle doesnt exist? wtf?
				if (_containerVehicle isEqualTo objNull) then 
				{
					throw TRADING_RESPONSE_INVALID_CONTAINER;
				};

				if !([_containerVehicle, _itemClassName] call ExileClient_util_containerCargo_canAdd) then 
				{
					throw TRADING_RESPONSE_NO_SPACE;
				};
			};
		};
	}
	catch
	{
		_tradingResult = _exception;
		_canBuyItem = false;
	};

	// Wait for the server to respond
	if (ExileClientIsWaitingForServerTradeResponse) then
	{
		_canBuyItem = false;
	};

	// The player can buy the item, enable all controls
	if (_canBuyItem) then 
	{
		_purchaseButton ctrlEnable true;
		_quantityDropdown ctrlEnable true;	
	}
	else 
	{
		// The player cant buy the item, mark the "LOAD" as red to indicate the container is full
		if (_tradingResult isEqualTo TRADING_RESPONSE_NO_SPACE) then
		{
			_inventoryLoadLabel ctrlSetTextColor COLOR_RED_ARRAY_SUBTLE;
			_inventoryLoadValue ctrlSetTextColor COLOR_RED_ARRAY_SUBTLE;
		};

		// Disable the purchase button
		_purchaseButton ctrlEnable false;
		_quantityDropdown ctrlEnable false;
	};

	// Deselect inventory list
	_inventoryListBox = _dialog displayCtrl IDC_TRADER_DIALOG_INVENTORY_LISTBOX;
	_inventoryListBox lbSetCurSel -1;
}
else 
{
	// Disable the purchase button
	_purchaseButton ctrlEnable false;
	_quantityDropdown ctrlEnable false;
};

true