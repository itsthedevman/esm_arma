/* ----------------------------------------------------------------------------
Function:
	ESMs_system_territory_resetPaymentCounter

Description:
	Resets the payment counter for any territories where the player has build rights

Parameters:
	_this - [String] The player's UID

Returns:
	Nothing

Examples:
	(begin example)

		_playerUID call ESMs_system_territory_resetPaymentCounter;

	(end)

Author:
	Exile Server Manager
	www.esmbot.com
	© 2018-current_year!() Bryan "WolfkillArcadia"

	This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License.
	To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/.
---------------------------------------------------------------------------- */

private _territoryIDs =
[
	("Exile_Construction_Flag_Static" allObjects 0), // Much faster than allMissionObjects
	{
		private _buildRights = _x getVariable ["ExileTerritoryBuildRights", []];
		if (_playerUID in _buildRights) then
		{
			_x getVariable ["ExileDatabaseID", -1]
		};
	},
	true
]
call ESMs_util_array_map;

["set_territory_payment_counter", _territoryIDs, 0] call ESMs_system_extension_call;

nil
