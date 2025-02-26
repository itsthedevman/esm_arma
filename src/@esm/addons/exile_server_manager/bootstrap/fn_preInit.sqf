/* ----------------------------------------------------------------------------
Function:
    ESM_fnc_preInit

Description:
    Compiles all the required functions and calls the preInit. Functions can be overwritten by using CfgExileCustomCode.

    ESM's functions are broken into two categories, ESMs and ESMc for server and client respectfully.
    The reason why this doesn't follow Exile's format of <thing>Server and <thing>Client is because ESMServer and ESMClient look weird to me. That's all.

Parameters:
    _this - [Nothing]

Returns:
    Nothing

Examples:
    (begin example)

        [] call ESM_fnc_preInit;

    (end)

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

{
    private _function = _x select 0;
    private _file = _x select 1;

    if (isText (missionConfigFile >> "CfgExileCustomCode" >> _function)) then
    {
        _file = getText (missionConfigFile >> "CfgExileCustomCode" >> _function);
    };

    private _fileContent = preprocessFileLineNumbers _file;

    if (_fileContent isEqualTo "") then
    {
        diag_log (
            format [
                "ERROR | Override of %1 in CfgExileCustomCode points to a non-existent file: %2. Defaulting to vanilla Exile Server Manager code!",
                _function,
                _file
            ]
        );

        _fileContent = preprocessFileLineNumbers (_x select 1);
    };

    missionNamespace setVariable [_function, compileFinal _fileContent];
}
forEach
[
    server_fn!("ESMs_command_add"),
    server_fn!("ESMs_command_demote"),
    server_fn!("ESMs_command_gamble"),
    server_fn!("ESMs_command_pay"),
    server_fn!("ESMs_command_player"),
    server_fn!("ESMs_command_promote"),
    server_fn!("ESMs_command_remove"),
    server_fn!("ESMs_command_reward"),
    server_fn!("ESMs_command_sqf"),
    server_fn!("ESMs_command_upgrade"),
    server_fn!("ESMs_object_player_updateRespect"),
    server_fn!("ESMs_system_account_isKnown"),
    server_fn!("ESMs_system_extension_call"),
    server_fn!("ESMs_system_extension_callback"),
    server_fn!("ESMs_system_extension_processResult"),
    server_fn!("ESMs_system_function_call"),
    server_fn!("ESMs_system_message_respond_to"),
    server_fn!("ESMs_system_message_respond_withError"),
    server_fn!("ESMs_system_network_discord_log"),
    server_fn!("ESMs_system_network_discord_send_to"),
	server_fn!("ESMs_system_process_preInit"),
    server_fn!("ESMs_system_process_postInit"),
    server_fn!("ESMs_system_reward_network_loadAllRequest"),
    server_fn!("ESMs_system_reward_network_redeemItemRequest"),
    server_fn!("ESMs_system_reward_network_redeemVehicleRequest"),
    server_fn!("ESMs_system_territory_checkAccess"),
    server_fn!("ESMs_system_territory_encodeID"),
    server_fn!("ESMs_system_territory_get"),
    server_fn!("ESMs_system_territory_incrementPaymentCounter"),
    server_fn!("ESMs_system_territory_resetPaymentCounter"),
    server_fn!("ESMs_util_array_all"),
    server_fn!("ESMs_util_array_isValidHashmap"),
    server_fn!("ESMs_util_array_map"),
    server_fn!("ESMs_util_command_handleFailure"),
    server_fn!("ESMs_util_command_handleSuccess"),
    server_fn!("ESMs_util_config_isValidClassName"),
    server_fn!("ESMs_util_embed_addField"),
    server_fn!("ESMs_util_embed_create"),
    server_fn!("ESMs_util_embed_setColor"),
    server_fn!("ESMs_util_embed_setDescription"),
    server_fn!("ESMs_util_embed_setTitle"),
    server_fn!("ESMs_util_extension_formatArmaError"),
    server_fn!("ESMs_util_extension_formatError"),
    server_fn!("ESMs_util_hashmap_dig"),
    server_fn!("ESMs_util_hashmap_fromArray"),
    server_fn!("ESMs_util_hashmap_key"),
    server_fn!("ESMs_util_hashmap_toArray"),
    server_fn!("ESMs_util_log"),
    server_fn!("ESMs_util_number_toString")
];

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
    network_fn!("ESMs_system_reward_network_loadAllRequest"),
    network_fn!("ESMs_system_reward_network_redeemItemRequest"),
    network_fn!("ESMs_system_reward_network_redeemVehicleRequest")
];

[] call ESMs_system_process_preInit;
