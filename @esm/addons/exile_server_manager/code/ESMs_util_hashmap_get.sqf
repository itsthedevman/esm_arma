/* ----------------------------------------------------------------------------
Function: ESMs_util_hashmap_get

Description:
	Attempts to retrieve the key(s) from the hashmap. If a key is not found, nil will be returned.
	Similar to Ruby's hash&.dig(:key_1)&.dig(:key_2)&.dig(:key_n)

Parameters:
	_hashMap 	- A hashmap to get the data from
	..._keys	- The key(s) to get from the hash

Returns:
	The value that is stored in the keys or nil if not found/does not exist

Examples:
	(begin example)

	[_hashMap, "key_1"] call ESMs_util_hashmap_get;
	[_hashMap, "key_1", "key_2"] call ESMs_util_hashmap_get;

	(end)

Author:
	Exile Server Manager
	www.esmbot.com
	© 2018-2022 Bryan "WolfkillArcadia"

	This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License.
	To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/.
---------------------------------------------------------------------------- */

private _hashMap = _this select 0;
private _keys = _this select [1, count(_this)];
private _lastIndex = count(_keys) - 1;

private _result = {
	private _key = _x;
	if (isNil "_hashMap" || { !(_hashMap isEqualType HASH_TYPE) }) exitWith { nil };

	_hashMap = _hashMap getOrDefault [_key, nil];
	if (_forEachIndex isEqualTo _lastIndex) exitWith
	{
		if (isNil "_hashMap") then { nil } else { _hashMap }
	};

	nil
}
forEach _keys;

// If a variable is nil, arma WILL NOT let you reference it. Hence why `isNil` only accepts a string ;)
if (isNil "_result") then { nil } else { _result }
