/* ----------------------------------------------------------------------------
Function:
	ExileServer_system_xm8_sendProtectionMoneyDue

Description:
	Notify players of the territory that their protection money is due

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

private _maintenancePeriod = getNumber(
	configFile >> "CfgSettings" >> "GarbageCollector" >> "Database" >> "territoryLifeTime"
);

private _territoryIDs = format [
	"getAllNotifTerritory:%1",
	_maintenancePeriod
]
call ExileServer_system_database_query_selectFull;

if (empty?(_territoryIDs)) exitWith { nil };

private _flags = allMissionObjects "Exile_Construction_Flag_Static";
if (empty?(_flags)) exitWith { nil };

// Grab the flags we care about
_flags =
[
	_flags,
	{
		if ((_this getVariable ["ExileDatabaseID", -1]) in _territoryIDs) then
		{
			_this
		};
	},
	true
]
call ESMs_util_array_map;

{
	private _territory = _x;
	private _territoryID = _territory getVariable ["ExileDatabaseID", -1];

	[
		"protection-money-due",
		_territory getVariable ["ExileTerritoryBuildRights", []],
		[
			[
				"territory_id",
				_territory call ESMs_system_territory_encodeID
			],
			[
				"territory_name",
				_territory getVariable ["ExileTerritoryName", ""]
			]
		]
	]
	call ExileServer_system_xm8_send;

	format["setTerritoryNotified:1:%1", _territoryID] call ExileServer_system_database_query_fireAndForget;
}
forEach _flags;

nil
