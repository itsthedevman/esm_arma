/* ----------------------------------------------------------------------------
Function:
	ESMs_util_embed_setTitle

Description:
	Sets the embed's title to the provided value

Parameters:
	_embed - [HashMap] The embed to set the title on
	_title - [String] The title to set

Returns:
	Nothing

Examples:
	(begin example)

		// _embed: {}
		private _embed = [] call ESMs_util_embed_create;

		// _embed: { title: "This is a title" }
		[_embed, "This is a title"] call ESMs_util_embed_setTitle;

	(end)

Author:
	Exile Server Manager
	www.esmbot.com
	© 2018-2023 Bryan "WolfkillArcadia"

	This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License.
	To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/.
---------------------------------------------------------------------------- */

(_this select 0) set ["description", _this select 1];
nil
