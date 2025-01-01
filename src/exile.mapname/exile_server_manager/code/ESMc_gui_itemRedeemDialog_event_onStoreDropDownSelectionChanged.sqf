disableSerialization;

if !(uiNameSpace getVariable ["RscExileTraderDialogIsInitialized", false]) exitWith {};

_listBox = _this select 0;
_index = _this select 1;
_dialog = uiNameSpace getVariable ["RscExileTraderDialog", displayNull];

// Cannot buy anything, because no selection
_storeListBox = _dialog displayCtrl IDC_TRADER_DIALOG_STORE_LISTBOX;
_storeListBox lbSetCurSel -1;
_inventoryListBox = _dialog displayCtrl IDC_TRADER_DIALOG_INVENTORY_LISTBOX;
_inventoryListBox lbSetCurSel -1;

"" call ExileClient_gui_traderDialog_updateItemStats;
call ExileClient_gui_traderDialog_updateStoreListBox;

true