disableSerialization;

_dialog = uiNameSpace getVariable ["RscExileTraderDialog", displayNull];

// Update player name
_playerName = _dialog displayCtrl IDC_TRADER_DIALOG_PLAYER_NAME;
_playerName ctrlSetText (toUpper profileName);

// Update player money
_playerPopTabs = player getVariable ["ExileMoney", 0];
_popTabsString = _playerPopTabs call ExileClient_util_string_exponentToString;
_playerMoney = _dialog displayCtrl IDC_TRADER_DIALOG_PLAYER_MONEY;
_playerMoney ctrlSetStructuredText (parseText format["<t size='1' font='puristaMedium' align='right'>%1<img image='\exile_assets\texture\ui\poptab_inline_ca.paa' size='1' shadow='true' /></t>", _popTabsString]);

true