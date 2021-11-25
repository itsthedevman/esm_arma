
/**
 *
 * Function:
 *      ESMs_command_sqf
 *
 * Description:
 *      Executes the provided SQF on the target (server, all players, or a single player)
 *
 *
 * * *
 *
 * Exile Server Manager
 * www.esmbot.com
 * © 2018-2021 Bryan "WolfkillArcadia"
 *
 * This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License.
 * To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/.
 *
 **/

private _id = _this getOrDefault ["id", nil];

/*
	execute_on: String. Valid options: "server", "all", "player"
	code: String
*/
private _data = _this getOrDefault ["data", nil];

/*
	player: HashMap
		steam_uid: String,
		discord_id: String,
		discord_name: String,
		discord_mention: String,
	target: HashMap | Nothing
		steam_uid: String,
		discord_id: String,
		discord_name: String,
		discord_mention: String,
*/
private _metadata = _this getOrDefault ["metadata", nil];
if (isNil "_id" || { isNil "_data" } || { isNil "_metadata" }) exitWith { nil };

try
{
	private _type = [_data, "execute_on"] call ESMs_util_hashmap_get;
	private _code = compile ([_data, "code"] call ESMs_util_hashmap_get);
	private _result = nil;

	switch (_type) do
	{
		case "all":
		{
			_code remoteExec ["call", -2];
		};

		case "server":
		{
			_result = call _code;
		};

		default
		{
			private _targetUID = [_metadata, "target", "steam_uid"] call ESMs_util_hashmap_get;
			private _targetMention = [_metadata, "target", "discord_mention"] call ESMs_util_hashmap_get;
			private _targetObject = _targetUID call ExileClient_util_player_objectFromPlayerUID;

			if (isNull _targetObject) then
			{
				throw format[localize "$STR_ESM_SqfExecute_NullPlayer", _targetMention, _targetUID, ESM_ServerID];
			};

			_code remoteExec ["call", owner _targetObject];
		};
	};

	[
		_id,
		"arma",
		"sqf_result",
		[
			[
				"result",
				if (isNil "_result") then { nil } else { str(_result) }
			]
		]
	]
	call ESMs_object_message_respond_to;
}
catch
{
	[_id, _exception] call ESMs_object_message_respond_withError;
};

nil
