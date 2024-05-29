/* ----------------------------------------------------------------------------
Function:
	ESMs_util_embed_setColor

Description:
	Sets the color of the provided embed

Parameters:
	_embed - [HashMap] The embed to modify
	_color - [String] The name of the color to set.
					  Valid colors:
						red, blue, green, yellow, orange, purple, pink, white

Returns:
	Nothing

Examples:
	(begin example)

		// _embed: {}
		private _embed = [] call ESMs_util_embed_create;

		// _embed: {"color": "blue"}
		[_embed, "blue"] call ESMs_util_embed_setColor;

	(end)

Author:
	Exile Server Manager
	www.esmbot.com
	© 2018-current_year!() Bryan "WolfkillArcadia"

	This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License.
	To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/.
---------------------------------------------------------------------------- */

private _embed = _this select 0;
private _value = _this select 1;

if (nil?(_value) || { empty?(_value) }) exitWith { nil };

_embed set ["color", _value];

nil
