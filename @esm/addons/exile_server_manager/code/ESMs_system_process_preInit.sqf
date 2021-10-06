/**
 *
 * Function:
 *      ESMs_system_process_preInit
 *
 * Description:
 *      Preps required variables and starts the client
 *
 * Arguments:
 *      None
 *
 * Examples:
 *      [] call ESMs_system_process_preInit;
 *
 * * *
 *
 * Exile Server Manager
 * www.esmbot.com
 * © 2018-2021 Bryan "WolfkillArcadia"
 *
 * This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License.
 * To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/.
 *
 **/

ESM_Version = "";
ESM_BuildNumber = "";
ESM_CommunityID = "";
ESM_DatabaseExtension = "extDB3";
ESM_ExtDBVersion = 3;
ESM_Gambling_Modifier = 1;
ESM_Gambling_PayoutBase = 95;
ESM_Gambling_PayoutRandomizerMax = 0;
ESM_Gambling_PayoutRandomizerMid = 0.5;
ESM_Gambling_PayoutRandomizerMin = 1;
ESM_Gambling_WinPercentage = 35;
ESM_Initialized = false;
ESM_Logging_AddPlayerToTerritory = true;
ESM_Logging_DemotePlayer = true;
ESM_Logging_Exec = true;
ESM_Logging_Gamble = false;
ESM_Logging_ModifyPlayer = true;
ESM_Logging_PayTerritory = true;
ESM_Logging_PromotePlayer = true;
ESM_Logging_RemovePlayerFromTerritory = true;
ESM_Logging_RewardPlayer = true;
ESM_Logging_TransferPoptabs = true;
ESM_Logging_UpgradeTerritory = true;
ESM_LoggingChannelID = "";
ESM_ServerID = "";
ESM_Taxes_TerritoryPayment = 0;
ESM_Taxes_TerritoryUpgrade = 0;
ESM_TerritoryAdminUIDs = [];

["preInit", "Exile Server Manager is booting..."] call ESMs_util_log;

// For controlling which calls log
ESM_LogLevel = "log_level" call ESMs_system_extension_call;
ESM_LogLevelLookup = createHashMapFromArray [["error", 0], ["warn", 1], ["info", 2], ["debug", 3], ["trace", 4]];

// Cache the territory prices to make calculating upgrade costs faster
private _territory_data = [];
{
	_territory_data pushBack [
		["level", _forEachIndex + 1],
		["purchase_price", _x select 0],
		["radius", _x select 1],
		["object_count", _x select 2]
	];
}
forEach (getArray(missionConfigFile >> "CfgTerritories" >> "prices"));

// Bind the callback to enable the extension to communicate with the a3 server
addMissionEventHandler ["ExtensionCallback", {
	params ["_name", "_function", "_data"];

	if (_name isEqualTo "exile_server_manager") then
	{
		[_function, _data] spawn ESMs_system_extension_callback;
	};
}];

// Send the data to the client
[
	// Rust function
	"pre_init",

	// server_name
	serverName,

	// price_per_object
	getNumber(missionConfigFile >> "CfgTerritories" >> "popTabAmountPerObject"),

	// territory_lifetime
	getNumber(configFile >> "CfgSettings" >> "GarbageCollector" >> "Database" >> "territoryLifeTime"),

	// territory_data
	_territory_data,

	// vg_enabled
	getNumber(missionConfigFile >> "CfgVirtualGarage" >> "enableVirtualGarage") isEqualTo 0,

	// vg_max_sizes
	getArray(missionConfigFile >> "CfgVirtualGarage" >> "numberOfVehicles")
] call ESMs_system_extension_call;

true
