/*
	Fires when the player double-clicks an item, which is a shortcut to buy an item without
	clicking the purchase button

	IN:
	CONTROL - The control handle for the store list box
	SCALAR - The index we have clicked on
*/

_storeListBox = _this select 0;
_clickedOnIndex = _this select 1;

// Check if the purchase button is active and if so, simulate a click on that (owww, am i lazy)
_dialog = uiNameSpace getVariable ["RscExileTraderDialog", displayNull];
_purchaseButton = _dialog displayCtrl IDC_TRADER_DIALOG_PURCHASE_BUTTON;

if (ctrlEnabled _purchaseButton) then
{
	// We do not use any of the parameters on the onPurchaseButtonClick event, so we can just call it directly
	call ExileClient_gui_traderDialog_event_onPurchaseButtonClick;
};

true