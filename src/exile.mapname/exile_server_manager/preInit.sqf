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
systemChat "Loading ESMc";
{
	private _code = preprocessFileLineNumbers (_x select 1);
	missionNamespace setVariable [(_x select 0), compileFinal _code];
}
forEach
[
	mission_fn!("ESMc_gui_itemRedeemDialog_event_onFilterCheckboxStateChanged"),
	mission_fn!("ESMc_gui_itemRedeemDialog_event_onPlayerInventoryDropDownSelectionChanged"),
	mission_fn!("ESMc_gui_itemRedeemDialog_event_onPlayerInventoryListBoxSelectionChanged"),
	mission_fn!("ESMc_gui_itemRedeemDialog_event_onRedeemButtonClick"),
	mission_fn!("ESMc_gui_itemRedeemDialog_event_onStoreDropDownSelectionChanged"),
	mission_fn!("ESMc_gui_itemRedeemDialog_event_onStoreListBoxItemDoubleClick"),
	mission_fn!("ESMc_gui_itemRedeemDialog_event_onStoreListBoxSelectionChanged"),
	mission_fn!("ESMc_gui_itemRedeemDialog_event_onUnload"),
	mission_fn!("ESMc_gui_itemRedeemDialog_show"),
	mission_fn!("ESMc_gui_itemRedeemDialog_updateInventoryDropdown"),
	mission_fn!("ESMc_gui_itemRedeemDialog_updateInventoryListBox"),
	mission_fn!("ESMc_gui_itemRedeemDialog_updatePlayerControls"),
	mission_fn!("ESMc_gui_itemRedeemDialog_updateStoreDropdown"),
	mission_fn!("ESMc_gui_itemRedeemDialog_updateStoreListBox"),
	mission_fn!("ESMc_gui_vehicleRedeemDialog_event_onCategoryDropDownSelectionChanged"),
	mission_fn!("ESMc_gui_vehicleRedeemDialog_event_onInputBoxChars"),
	mission_fn!("ESMc_gui_vehicleRedeemDialog_event_onRedeemButtonClick"),
	mission_fn!("ESMc_gui_vehicleRedeemDialog_event_onUnload"),
	mission_fn!("ESMc_gui_vehicleRedeemDialog_event_onVehicleListBoxSelectionChanged"),
	mission_fn!("ESMc_gui_vehicleRedeemDialog_show"),
	mission_fn!("ESMc_gui_vehicleRedeemDialog_updateVehicleListBox"),
	mission_fn!("ESMc_gui_vehicleRedeemDialog_updateVehicle"),
	mission_fn!("ESMc_system_reward_network_loadAllResponse"),
	mission_fn!("ESMc_system_reward_network_redeemItemResponse"),
	mission_fn!("ESMc_system_reward_network_redeemVehicleResponse")
];

systemChat "Loading ESMc network messages";

////////////////////////////////////////////////////
// Allows forwarding Exile network messages to ESM functions
{
    private _exileFunction = _x select 0;
    private _esmFunction = _x select 1;

    private _code = missionNamespace getVariable [_esmFunction, {}];

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

systemChat "Finished loading";
