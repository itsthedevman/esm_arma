disableSerialization;

_dialog = uiNameSpace getVariable ["RscExileTraderDialog", displayNull];

// Update inventory dropdown
_inventoryDropdown = _dialog displayCtrl IDC_TRADER_DIALOG_INVENTORY_DROPDOWN;

lbClear _inventoryDropdown;

//_index = _inventoryDropdown lbAdd (profileName);
_index = _inventoryDropdown lbAdd "Equipment";
_inventoryDropdown lbSetValue [_index, TRADE_CONTAINER_EQUIPMENT];
_inventoryDropdown lbSetPicture [_index, "a3\ui_f\data\gui\Rsc\RscDisplayArsenal\face_ca.paa"];
_inventoryDropdown lbSetCurSel 0;

if !((uniform player) isEqualTo "") then
{
	_index = _inventoryDropdown lbAdd "Uniform";
	_inventoryDropdown lbSetPicture [_index, "a3\ui_f\data\gui\Rsc\RscDisplayArsenal\uniform_ca.paa"];
	_inventoryDropdown lbSetValue [_index, TRADE_CONTAINER_UNIFORM];
};

if !((vest player) isEqualTo "") then
{
	_index = _inventoryDropdown lbAdd "Vest";
	_inventoryDropdown lbSetPicture [_index, "a3\ui_f\data\gui\Rsc\RscDisplayArsenal\vest_ca.paa"];
	_inventoryDropdown lbSetValue [_index, TRADE_CONTAINER_VEST];
};

if !((backpack player) isEqualTo "") then
{
	_index = _inventoryDropdown lbAdd "Backpack";
	_inventoryDropdown lbSetPicture [_index, "a3\ui_f\data\gui\Rsc\RscDisplayArsenal\backpack_ca.paa"];
	_inventoryDropdown lbSetValue [_index, TRADE_CONTAINER_BACKPACK];
};

_nearVehicles = nearestObjects [player, ["LandVehicle", "Air", "Ship"], 80];

{
	if (local _x) then
	{
		if (alive _x) then
		{
			_index = _inventoryDropdown lbAdd getText(configFile >> "CfgVehicles" >> (typeOf _x) >> "displayName");
			//_inventoryDropdown lbSetPicture [_index, "a3\ui_f\data\gui\Rsc\RscDisplayArsenal\backpack_ca.paa"];
			_inventoryDropdown lbSetData [_index, netId _x];
			_inventoryDropdown lbSetValue [_index, TRADE_CONTAINER_VEHICLE];
		};
	};
}
forEach _nearVehicles;

true