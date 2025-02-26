/* ----------------------------------------------------------------------------
Function:
	ESMc_gui_itemRedeemDialog_updateInventoryDropdown

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

systemChat "2.1";
private _dialog = uiNameSpace getVariable ["RscEsmItemRedeemDialog", displayNull];

// Update inventory dropdown
private _inventoryDropdown = _dialog displayCtrl const!(IDC_ITEM_DIALOG_INVENTORY_DROPDOWN);

lbClear _inventoryDropdown;

private _index = _inventoryDropdown lbAdd "Equipment";
_inventoryDropdown lbSetValue [_index, const!(TRADE_CONTAINER_EQUIPMENT)];
_inventoryDropdown lbSetPicture [_index, "a3\ui_f\data\gui\Rsc\RscDisplayArsenal\face_ca.paa"];
_inventoryDropdown lbSetCurSel 0;

if !((uniform player) isEqualTo "") then
{
	_index = _inventoryDropdown lbAdd "Uniform";

	_inventoryDropdown lbSetPicture [
		_index, "a3\ui_f\data\gui\Rsc\RscDisplayArsenal\uniform_ca.paa"
	];

	_inventoryDropdown lbSetValue [_index, const!(TRADE_CONTAINER_UNIFORM)];
};

if !((vest player) isEqualTo "") then
{
	_index = _inventoryDropdown lbAdd "Vest";
	_inventoryDropdown lbSetPicture [_index, "a3\ui_f\data\gui\Rsc\RscDisplayArsenal\vest_ca.paa"];
	_inventoryDropdown lbSetValue [_index, const!(TRADE_CONTAINER_VEST)];
};

if !((backpack player) isEqualTo "") then
{
	_index = _inventoryDropdown lbAdd "Backpack";

	_inventoryDropdown lbSetPicture [
		_index, "a3\ui_f\data\gui\Rsc\RscDisplayArsenal\backpack_ca.paa"
	];

	_inventoryDropdown lbSetValue [_index, const!(TRADE_CONTAINER_BACKPACK)];
};

private _nearVehicles = nearestObjects [player, ["LandVehicle", "Air", "Ship"], 80];

{
	if (local _x) then
	{
		if (alive _x) then
		{
			_index = _inventoryDropdown lbAdd getText(
				configFile >> "CfgVehicles" >> (typeOf _x) >> "displayName"
			);

			_inventoryDropdown lbSetData [_index, netId _x];
			_inventoryDropdown lbSetValue [_index, const!(TRADE_CONTAINER_VEHICLE)];
		};
	};
}
forEach _nearVehicles;

systemChat "2.2";
true
