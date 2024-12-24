/* ----------------------------------------------------------------------------
Function:
	ESMs_util_config_isValidClassName

Description:
	Checks if a provided classname is valid on this server.
	This only works for classes defined in CfgMagazines, CfgVehicles,
	CfgAmmo, CfgGlasses, or CfgWeapons.

Parameters:
	_this - [String] The classname to check

Returns:
	Boolean

Examples:
	(begin example)

		"ItemGPS" call ESMs_util_config_isValidClassName; // true
		"arifle_NoobDestroyer" call ESMs_util_config_isValidClassName; // false

	(end)

Author:
	Exile Server Manager
	www.esmbot.com
	© 2018-current_year!() Bryan "WolfkillArcadia"

	This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License.
	To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/.
---------------------------------------------------------------------------- */

switch (true) do
{
	case isClass(configFile >> "CfgMagazines" >> _this);
	case isClass(configFile >> "CfgWeapons" >> _this);
	case isClass(configFile >> "CfgVehicles" >> _this);
	case isClass(configFile >> "CfgAmmo" >> _this);
	case isClass(configFile >> "CfgGlasses" >> _this): 		{ true  };
	default													{ false };
};
