/**
 * ESM_system_extension_processResults
 * 	Processes the result from a callExtension. This function also handles chunked messages, making extra calls to the extension if need be.
 *
 * Exile Server Manager
 * www.esmbot.com
 * © 2018-2021 WolfkillArcadia
 *
 * This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License.
 * To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/.
 */

/*
	This result is always the same format: [id, status_code, content]
		id 			<String, nil> If the message has multiple parts, this is the chunking ID. Use it to get the next chunk.
		status_code <Scalar> -1: Error. 0: Success/No more chunks, 1: Has more data
		content		<String> The data with this message. If the status_code is -1, this will be the error message
*/
private _result = _this;

if (isNil("_result") || { _result isEqualTo "" }) exitWith {
	["processResult", "This function cannot be called with nil or """"", "error"] call ESMs_util_log;
};

if (_result isEqualType "") then {
	_result = parseSimpleArray _result;
};

if (_result isEqualTo []) exitWith {
	["processResult", format["Failed to parse %1", _this], "error"] call ESMs_util_log;
};

private _id = _result select 0;
private _statusCode = _result select 1;
private _content = _result select 2;

// Success with nothing more to retrieve. Return it
if (_statusCode isEqualTo 0) exitWith { _content };

// There was an error
if (_statusCode isEqualTo -1) exitWith {
	["processResult", format["ERROR - %1", _content]] call ESMs_util_log;
	nil
};

// There are more messages to process
_content + (["next_chunk", _id] call ESMs_system_extension_call)
