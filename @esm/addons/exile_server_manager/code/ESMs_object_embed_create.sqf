/* ----------------------------------------------------------------------------
Function: ESMs_object_embed_create

Description:
	Creates a hashmap representation of an embed.

Parameters:
	_this 	-> An hashmap in array form containing valid embed attribute and the value to assign. Valid attributes: title, description, color, fields

Returns:
	A validated hashmap containing the provided data.

Examples:
	(begin example)

	[["title", "description"], ["This is the title", "This is a description"]] call ESMs_object_embed_create;

	(end)

Author:
	Exile Server Manager
	www.esmbot.com
	© 2018-2022 Bryan "WolfkillArcadia"

	This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License.
	To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/.
---------------------------------------------------------------------------- */


private _embedData = _this;
private _embed = createHashMap;
if (isNil "_embedData") exitWith { _embed };

if (_embedData isEqualType ARRAY_TYPE && { _embedData call ESMs_util_array_isValidHashmap }) then
{
	_embedData = _embedData call ESMs_util_hashmap_fromArray;
};

if !(_embedData isEqualType HASH_TYPE) exitWith { _embed };

private _validKeys = ["title", "description", "color", "fields"];
{
	if (
		!(isNil "_x") && {
			_x in _validKeys && {
				!(isNil "_y") && {
					_y isEqualType ""
				}
			}
		}
	) then
	{
		_embed set [_x, _y];
	};
}
forEach _embedData;

_embed
