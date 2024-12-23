/* ----------------------------------------------------------------------------
Function: ESMs_system_message_respond_to

Description:
	Used to respond to a incoming message with data, or to just say "ack". Every incoming message must be acknowledged, at the very least.

Parameters:
	_id				- The ID of the message to respond to. [String]
	_type			- The type of message [String]
	_data			- The data to send along with the outgoing message. Defaults to []. [HashMap, Array]
	_metadata		- The metadata to send along with the outgoing message. Defaults to []. [HashMap, Array]
	_errors		 	- An array of error objects. Defaults to []. See example [Array<Array<String>>]

Returns:
	The response from the extension which defaults to ""

Examples:
	(begin example)

	// ack the message.
	["id"] call ESMs_system_message_respond_to;

	// Or send a message with everything
	[
		"id",
		"type",
		[
			["data_key_1", "data_value_1"],
			["data_key_2", "data_value_2"]
		],
		[
			["metadata_key_1", "metadata_value_1"],
			["metadata_key_2", "metadata_value_2"]
		],
		[
			["code", "ERROR_CODE"],
			["message", "This is an error message"]
		]
	] call ESMs_system_message_respond_to;

	(end)

Author:
	Exile Server Manager
	www.esmbot.com
	© 2018-current_year!() Bryan "WolfkillArcadia"

	This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License.
	To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/.
---------------------------------------------------------------------------- */

params [
	"_id",
	["_type", "ack", [rv_type!(STRING)]],
	["_data", [], [rv_type!(ARRAY), rv_type!(HASH)]],
	["_metadata", [], [rv_type!(ARRAY), rv_type!(HASH)]],
	["_errors", [], [rv_type!(ARRAY)]]
];

// Errors must be hashmap arrays
private _errorPackage = [];
{
	if (isNil "_x") then { continue; };

	// Only accepts ["code", "content"] or ["message", "content"]
	if !(
		type?(_x, ARRAY) && {
			[_x, { type?(_this, STRING) }] call ESMs_util_array_all && {
				count(_x) isEqualTo 2
			}
		}
	) then { continue; };

	_errorPackage pushBack [["type", _x select 0], ["content", _x select 1]];
}
forEach _errors;

// Inserts the "content" section of Data/Metadata only if it is needed
private _validator = {
	private _data = _this;
	private _package = [];

	if (empty?(_data)) exitWith { _package };

	_package pushBack ["content", _this select 1];
	_package
};


// Send it!
[
	"send_message",
	_id,
	_type,
	_data,
	_metadata,
	_errorPackage
]
call ESMs_system_extension_call
