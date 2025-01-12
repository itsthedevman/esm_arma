/* ----------------------------------------------------------------------------
Function:
	ESMs_system_reward_network_redeemItemRequest

Description:
	TODO

Author:
	Exile Mod
	www.exilemod.com
	© 2015-current_year!() Exile Mod Team

	This work is licensed under the Creative Commons Attribution-NonCommercial-NoDerivatives 4.0 International License.
	To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-nd/4.0/.

Co-author:
	Exile Server Manager
	www.esmbot.com
	© 2018-current_year!() Bryan "WolfkillArcadia"

	This work is licensed under the Creative Commons Attribution-NonCommercial-NoDerivatives 4.0 International License.
	To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-nd/4.0/.
---------------------------------------------------------------------------- */

private _sessionID = _this select 0;
private _parameters = _this select 1;
private _rewardCode = _parameters select 0;
private _containerType = _parameters select 1;
private _containerNetID = _parameters select 2;

try
{
	private _playerObject = _sessionID call ExileServer_system_session_getPlayerObject;
	if (_playerObject getVariable ["ExileMutex",false]) then
	{
		throw TRADING_RESPONSE_MUTEX;
	};

	_playerObject setVariable ["ExileMutex",true];

	private _vehicleObject = objNull;
	if (isNull _playerObject) then
	{
		throw const!(TRADING_RESPONSE_INVALID_PLAYER);
	};

	// Check if we are storing to a vehicle so it saves
	if (_containerType isEqualTo const!(TRADE_CONTAINER_VEHICLE)) then
	{
		_vehicleObject = objectFromNetID(_containerNetID);
		if (isNull _vehicleObject) then
		{
			throw const!(TRADING_RESPONSE_INVALID_VEHICLE);
		};
	};

	// The dead may not redeem stuff
	if !(alive _playerObject) then
	{
		throw const!(TRADING_RESPONSE_DEAD_PLAYER);
	};

	// Load the reward
	private _reward = _rewardCode call ESMs_system_reward_database_load;

	// Make sure we have the valid reward ID
	if (nil?(_reward)) then
	{
		throw const!(TRADING_RESPONSE_INVALID_REWARD);
	};

	// The good stuff
	private _rewardType = get!(_reward, "type");
	private _itemClassname = get!(_reward, "classname");
	private _quantity = get!(_reward, "quantity");

	switch (_rewardType) do
	{
		case "poptabs":
		{
			private _playerMoney = _playerObject getVariable ["ExileMoney", 0];

			_playerMoney = _playerMoney + _quantity;
			_playerObject setVariable ["ExileMoney", _playerMoney, true];

			format[
				"setPlayerMoney:%1:%2",
				_playerMoney,
				_playerObject getVariable ["ExileDatabaseID", 0]
			] call ExileServer_system_database_query_fireAndForget;
		};

		case "respect":
		{
			private _playerRespect = _playerObject getVariable ["ExileScore", 0];

			_playerRespect = _playerRespect + _quantity;
			_playerObject setVariable ["ExileScore", _playerRespect];

			format[
				"setAccountScore:%1:%2",
				_playerRespect,
				_playerUID
			] call ExileServer_system_database_query_fireAndForget;
		};

		case "classname":
		{
			// Disallow vehicles because this isn't the way to do it
			if (isClass (configFile >> "CfgVehicles" >> _itemClassname)) then
			{
				throw const!(TRADING_RESPONSE_INVALID_VEHICLE);
			};

			// Check if the item class is valid
			if !(isClass (missionConfigFile >> "CfgExileArsenal" >> _itemClassname)) then
			{
				throw const!(TRADING_RESPONSE_INVALID_OBJECT_CLASS);
			};

			// Don't do anything, Exile lets the client handle it, I'll let the client handle it
			// Though I'll be grumpy about it
		};

		default
		{
			throw const!(TRADING_RESPONSE_INVALID_REWARD_TYPE);
		};
	};

	// Update the database
	// For items, the quantity redeemed will always been the the quantity that is available
	[_rewardCode, _quantity] call ESMs_system_reward_database_redeem;

	// Send response
	[
		_sessionID,
		"redeemItemResponse",
		[
			const!(TRADING_RESPONSE_OK),
			_rewardType,
			_itemClassname,
			_quantity,
			_containerType,
			_containerNetID
		]
	] call ExileServer_system_network_send_to;

	// extDB logging
	private _logging = getNumber(configFile >> "CfgSettings" >> "Logging" >> "traderLogging");
	if (_logging isEqualTo 1) then
	{
		private _traderLog = format [
			"PLAYER: ( %1 ) %2 PURCHASED ITEM %3 FOR %4 POPTABS | PLAYER TOTAL MONEY: %5",
			getPlayerUID _playerObject,
			_playerObject,
			_itemClassname,
			_salesPrice,
			_playerMoney
		];

		ESM_DatabaseExtension callExtension format["1:TRADING:%1", _traderLog];
	};

	// If the item was placed inside of the vehicle, save the vehicle in our database
	if (_vehicleObject isNotEqualTo objNull) then
	{
		_vehicleObject call ExileServer_object_vehicle_database_update;
	}
	else
	{
		// Item was stored in the inventory, so save that
		_playerObject call ExileServer_object_player_database_update;
	};
}
catch
{
	private _responseCode = _exception;

	[
		_sessionID, "redeemItemResponse",
		[_responseCode, 0, "", 0, 0, ""]
	] call ExileServer_system_network_send_to;
};

_playerObject setVariable ["ExileMutex", false];

true
