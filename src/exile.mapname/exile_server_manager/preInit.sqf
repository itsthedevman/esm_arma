/* ----------------------------------------------------------------------------
Description:
	Loads ESM's client side code

Author:
	Exile Server Manager
	www.esmbot.com
	© 2018-current_year!() Bryan "WolfkillArcadia"

	This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License.
	To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/.
---------------------------------------------------------------------------- */

if (!hasInterface || isServer) exitWith {};

{
	private _code = preprocessFileLineNumbers (_x select 1);
	missionNamespace setVariable [(_x select 0), compileFinal _code];
}
forEach
[
	define_fn!("ESMc_gui_itemRedeemDialog_event_onFilterCheckboxStateChanged"),
	define_fn!("ESMc_gui_itemRedeemDialog_event_onPlayerInventoryDropDownSelectionChanged"),
	define_fn!("ESMc_gui_itemRedeemDialog_event_onPlayerInventoryListBoxSelectionChanged"),
	define_fn!("ESMc_gui_itemRedeemDialog_event_onPurchaseButtonClick"),
	define_fn!("ESMc_gui_itemRedeemDialog_event_onStoreDropDownSelectionChanged"),
	define_fn!("ESMc_gui_itemRedeemDialog_event_onStoreListBoxItemDoubleClick"),
	define_fn!("ESMc_gui_itemRedeemDialog_event_onStoreListBoxSelectionChanged"),
	define_fn!("ESMc_gui_itemRedeemDialog_event_onUnload"),
	define_fn!("ESMc_gui_itemRedeemDialog_show"),
	define_fn!("ESMc_gui_itemRedeemDialog_updateInventoryDropdown"),
	define_fn!("ESMc_gui_itemRedeemDialog_updateInventoryListBox"),
	define_fn!("ESMc_gui_itemRedeemDialog_updatePlayerControls"),
	define_fn!("ESMc_gui_itemRedeemDialog_updateStoreDropdown"),
	define_fn!("ESMc_gui_itemRedeemDialog_updateStoreListBox"),
	define_fn!("ESMc_gui_vehicleRedeemDialog_event_onCategoryDropDownSelectionChanged"),
	define_fn!("ESMc_gui_vehicleRedeemDialog_event_onInputBoxChars"),
	define_fn!("ESMc_gui_vehicleRedeemDialog_event_onPurchaseButtonClick"),
	define_fn!("ESMc_gui_vehicleRedeemDialog_event_onUnload"),
	define_fn!("ESMc_gui_vehicleRedeemDialog_event_onVehicleListBoxSelectionChanged"),
	define_fn!("ESMc_gui_vehicleRedeemDialog_show"),
	define_fn!("ESMc_gui_vehicleRedeemDialog_updateVehicleListBox"),
	define_fn!("ESMc_gui_vehicleRedeemDialog_updateVehicle"),
	define_fn!("ESMc_system_reward_network_loadAllResponse"),
	define_fn!("ESMc_system_reward_network_redeemItemResponse"),
	define_fn!("ESMc_system_reward_network_redeemVehicleResponse")
];

////////////////////////////////////////////////////
// Allows forwarding Exile network messages to ESM functions
{
    private _exileFunction = _x select 0;
    private _esmFunction = _x select 1;

    private _code = missionNamespace getVariable [_function, {}];

    if (_code isEqualTo {}) then
    {
        diag_log (
            format [
                "ERROR | Attempted to delegate %1 to an empty function. %2 may be empty or not defined",
                _exileFunction,
                _esmFunction
            ]
        );

        continue;
    };

    missionNamespace setVariable [_exileFunction, _esmFunction];
}
forEach
[
	network_fn!("ESMc_system_reward_network_loadAllResponse"),
	network_fn!("ESMc_system_reward_network_redeemItemResponse"),
	network_fn!("ESMc_system_reward_network_redeemVehicleResponse")
];
