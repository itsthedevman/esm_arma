disableSerialization;

if !(uiNameSpace getVariable ["RscExileTraderDialogIsInitialized", false]) exitWith {};

_listBox = _this select 0;
_index = _this select 1;
_dialog = uiNameSpace getVariable ["RscExileTraderDialog", displayNull];
_sellButton = _dialog displayCtrl IDC_TRADER_DIALOG_SELL_BUTTON;

// If we are waiting for the server to respond, disable the button
if (ExileClientIsWaitingForServerTradeResponse) then
{
	_sellButton ctrlEnable false;
}
else 
{
	if (_index > -1) then
	{
		_itemClassName = _listBox lbData _index;
		_itemClassName call ExileClient_gui_traderDialog_updateItemStats;

		// If the item is unsalable, deactive the "sell" button
		_sellButton ctrlEnable !(_listBox lbValue _index isEqualTo -1);

		// Deselect store list
		_storeListBox = _dialog displayCtrl IDC_TRADER_DIALOG_STORE_LISTBOX;
		_storeListBox lbSetCurSel -1;
	}
	else 
	{
		_sellButton ctrlEnable false;
	};
};

true