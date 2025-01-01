/*
	Gets triggered when the player presses the "Purchase" button in the trader dialog.
*/

disableSerialization;

// To prevent chained event triggering:
if !(uiNameSpace getVariable ["RscExileTraderDialogIsInitialized", false]) exitWith {};

// Get the dialog handle
_dialog = uiNameSpace getVariable ["RscExileTraderDialog", displayNull];

// Disable le buttons
_sellButton = _dialog displayCtrl IDC_TRADER_DIALOG_SELL_BUTTON;
_sellButton ctrlEnable false;
_sellButton ctrlCommit 0;

_purchaseButton = _dialog displayCtrl IDC_TRADER_DIALOG_PURCHASE_BUTTON;
_purchaseButton ctrlEnable false;
_purchaseButton ctrlCommit 0;

// Retrieve the store list box + selected item
_storeListBox = _dialog displayCtrl IDC_TRADER_DIALOG_STORE_LISTBOX;
_selectedStoreListBoxIndex = lbCurSel _storeListBox;

if !(_selectedStoreListBoxIndex isEqualTo -1) then
{
	_itemClassName = _storeListBox lbData _selectedStoreListBoxIndex;
	_quantity = 1; // TODO: Allow purchasing of quantity > 1 in version 2
	
	if !(_itemClassName isEqualTo "") then
	{
		// No button spam
		if !(ExileClientIsWaitingForServerTradeResponse) then
		{
			// Retrieve the current container type from the player to see where she/he wants to buy the item to
			_inventoryDropdown = _dialog displayCtrl IDC_TRADER_DIALOG_INVENTORY_DROPDOWN;
			_selectedInventoryDropdownIndex = lbCurSel _inventoryDropdown;
			_currentContainerType = _inventoryDropdown lbValue _selectedInventoryDropdownIndex;
			_containerNetID = "";

			// If the container type is a vehicle, community the net ID
			if (_currentContainerType isEqualTo TRADE_CONTAINER_VEHICLE) then
			{
				_containerNetID = _inventoryDropdown lbData _selectedInventoryDropdownIndex;
			};

			// Say hello to le server and expect it to be polite
			ExileClientIsWaitingForServerTradeResponse = true;

			["purchaseItemRequest", [_itemClassName, _quantity, _currentContainerType, _containerNetID]] call ExileClient_system_network_send;
		};
	};
};

true