/* ----------------------------------------------------------------------------
Function:
	ExileServer_system_xm8_sendFlagStealStarted

Description:
	Notify players of the territory that the flag is being stolen

Parameters:
	_this - [Object] The territory flag

Author:
	Exile Server Manager
	www.esmbot.com
	© 2018-current_year!() Bryan "WolfkillArcadia"

	This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License.
	To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/.
---------------------------------------------------------------------------- */

[
	"flag-steal-started",
	_this getVariable ["ExileTerritoryBuildRights", []],
	[
		[
			"territory_id",
			_this call ESMs_system_territory_encodeID
		],
		[
			"territory_name",
			_this getVariable ["ExileTerritoryName", ""]
		]
	]
]
call ExileServer_system_xm8_send;

nil
