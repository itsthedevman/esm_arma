/* ----------------------------------------------------------------------------
Function:
	ESMs_system_function_call

Description:
	Allows directly calling a provided SQF function with arguments.
	Automatically handles message acknowledgement and allows non-ESM functions
	to be used within ESM

Parameters:
	_this - [HashMap]

Examples:
	(begin example)

		[
			_messageID,
			[
				["target_function", "BIS_fnc_hasItem"],
				["arguments", [getObjectFromNetId "123:1", "ItemGPS"]]
			]
		]
		call ESMs_system_function_call;

	(end)

Author:
	Exile Server Manager
	www.esmbot.com
	© 2018-current_year!() Bryan "WolfkillArcadia"

	This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License.
	To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/.
---------------------------------------------------------------------------- */

private _id = get!(_this, "id");

/*
	target_function: String
	arguments: Any
*/
private _data = get!(_this, "data");

if (isNil "_id" || { isNil "_data" }) exitWith { nil };

try
{
	private _functionName = get!(_data, "target_function");
	if (nil?(_functionName)) then
	{
		throw "Missing function name";
	};

	private _function = missionNamespace getVariable [_functionName, nil];
	if (nil?(_function)) then
	{
		throw format["Function '%1' is not defined", _functionName];
	};

	private _arguments = get!(_data, "arguments");
	private _result = _arguments call _function;

	[
		_id,
		const!(ACK),
		[["result", returns_nil!(_result)]]
	]
	call ESMs_system_message_respond_to;
}
catch
{
	[_id, _exception] call ESMs_system_message_respond_withError;
};

nil
