/* ----------------------------------------------------------------------------
Function:
	ESMc_gui_itemRedeemDialog_event_onRedeemButtonClick

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

// To prevent chained event triggering:
if !(uiNameSpace getVariable ["RscRedeemDialogIsInitialized", false]) exitWith {};

// Get the dialog handle
private _dialog = uiNameSpace getVariable ["RscEsmItemRedeemDialog", displayNull];

// Disable le buttons
private _sellButton = _dialog displayCtrl const!(IDC_ITEM_DIALOG_REDEEM_BUTTON);
_sellButton ctrlEnable false;
_sellButton ctrlCommit 0;

private _purchaseButton = _dialog displayCtrl const!(IDC_ITEM_DIALOG_REDEEM_BUTTON);
_purchaseButton ctrlEnable false;
_purchaseButton ctrlCommit 0;

// Retrieve the store list box + selected item
private _storeListBox = _dialog displayCtrl const!(IDC_ITEM_DIALOG_STORE_LIST);
private _selectedStoreListBoxIndex = lbCurSel _storeListBox;

if (_selectedStoreListBoxIndex isEqualTo -1) exitWith {};

private _itemClassName = _storeListBox lbData _selectedStoreListBoxIndex;
if (_itemClassName isEqualTo "") exitWith {};

// No button spam
if (ExileClientIsWaitingForServerTradeResponse) exitWith {};

// Retrieve the current container type from the player to see
// where they want to buy the item to
private _inventoryDropdown = _dialog displayCtrl const!(IDC_ITEM_DIALOG_INVENTORY_DROPDOWN);

private _selectedInventoryDropdownIndex = lbCurSel _inventoryDropdown;
private _currentContainerType = _inventoryDropdown lbValue _selectedInventoryDropdownIndex;

// If the container type is a vehicle, community the net ID
private _containerNetID = "";
if (_currentContainerType isEqualTo const!(TRADE_CONTAINER_VEHICLE)) then
{
	_containerNetID = _inventoryDropdown lbData _selectedInventoryDropdownIndex;
};

// Say hello to le server and expect it to be polite
ExileClientIsWaitingForServerTradeResponse = true;

[
	"redeemItemRequest", [_itemClassName, _currentContainerType, _containerNetID]
] call ExileClient_system_network_send;

true
