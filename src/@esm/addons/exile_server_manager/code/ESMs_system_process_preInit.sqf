/* ----------------------------------------------------------------------------
Function:
	ESMs_system_process_preInit

Description:
	Preps required variables and starts the client

Parameters:
	_this - [Nothing]

Returns:
	Nothing

Examples:
	(begin example)

		[] call ESMs_system_process_preInit;

	(end)

Author:
	Exile Server Manager
	www.esmbot.com
	© 2018-current_year!() Bryan "WolfkillArcadia"

	This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License.
	To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/.
---------------------------------------------------------------------------- */

ESM_BuildNumber = "";
ESM_CommunityID = "";
ESM_DatabaseExtension = "extDB3";
ESM_ExtDBVersion = 3;
ESM_Gambling_LockerLimitEnabled = true;
ESM_Gambling_Modifier = 1;
ESM_Gambling_PayoutBase = 95;
ESM_Gambling_PayoutModifier = 0.95;
ESM_Gambling_PayoutRandomizer = [0, 0.5, 1];
ESM_Gambling_PayoutRandomizerMax = ESM_Gambling_PayoutRandomizer select 2;
ESM_Gambling_PayoutRandomizerMid = ESM_Gambling_PayoutRandomizer select 1;
ESM_Gambling_PayoutRandomizerMin = ESM_Gambling_PayoutRandomizer select 0;
ESM_Gambling_WinPercentage = 0.35;
ESM_Initialized = false;
ESM_Logging_CommandAdd = true;
ESM_Logging_CommandDemote = true;
ESM_Logging_CommandSqf = true;
ESM_Logging_CommandGamble = false;
ESM_Logging_CommandPlayer = true;
ESM_Logging_CommandPay = true;
ESM_Logging_CommandPromote = true;
ESM_Logging_CommandRemove = true;
ESM_Logging_CommandReward = true;
ESM_Logging_CommandTransfer = true;
ESM_Logging_CommandUpgrade = true;
ESM_LoggingChannelID = "";
ESM_LogLevel = "info";
ESM_LogLevelLookup = createHashMapFromArray [["error", 0], ["warn", 1], ["info", 2], ["debug", 3], ["trace", 4]];
ESM_LogOutput = "extension";
ESM_ServerID = "";
ESM_Taxes_TerritoryPayment = 0;
ESM_Taxes_TerritoryUpgrade = 0;
ESM_TerritoryAdminUIDs = [];
ESM_Version = "2.0.0";

info!("Exile Server Manager (mod) is booting");
ESM_LogLevel = "log_level" call ESMs_system_extension_call;
ESM_LogOutput = "log_output" call ESMs_system_extension_call;

// Cache the territory prices to make calculating upgrade costs faster
private _territoryData = [];
{
	_territoryData pushBack
	[
		["level", _forEachIndex],
		["purchase_price", _x select 0],
		["radius", _x select 1],
		["object_count", _x select 2]
	];
}
forEach (getArray(missionConfigFile >> "CfgTerritories" >> "prices"));

// Bind the callback to enable the extension to communicate with the a3 server
addMissionEventHandler ["ExtensionCallback", {
	// 0: name, 1: function, 2: data
	if ((_this select 0) isEqualTo "exile_server_manager") then
	{
		[_this select 1, _this select 2] spawn ESMs_system_extension_callback;
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
	_territoryData,

	// vg_enabled
	getNumber(missionConfigFile >> "CfgVirtualGarage" >> "enableVirtualGarage") isEqualTo 0,

	// vg_max_sizes
	getArray(missionConfigFile >> "CfgVirtualGarage" >> "numberOfVehicles")
]
call ESMs_system_extension_call;

true
