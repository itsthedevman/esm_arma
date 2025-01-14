/* ----------------------------------------------------------------------------
Function:
	ESMs_system_reward_network_redeemVehicleRequest

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
private _pinCode = _parameters select 1;

try
{
	private _playerObject = _sessionID call ExileServer_system_session_getPlayerObject;

	if (isNull _playerObject) then
	{
		throw const!(TRADING_RESPONSE_INVALID_PLAYER);
	};

	if !(alive _playerObject) then
	{
		throw const!(TRADING_RESPONSE_DEAD_PLAYER);
	};

	if (_playerObject getVariable ["ExileMutex", false]) then
	{
		throw const!(TRADING_RESPONSE_MUTEX);
	};

	_playerObject setVariable ["ExileMutex", true];

	// Load the reward
	private _reward = _rewardCode call ESMs_system_reward_database_load;

	// Make sure we have the valid reward ID
	if (nil?(_reward)) then
	{
		throw const!(TRADING_RESPONSE_INVALID_REWARD);
	};

	// The good stuff
	private _vehicleClassname = get!(_reward, "classname");

	// Check if the vehicle class is valid (you cannot buy jets etc.)
	if !(isClass (missionConfigFile >> "CfgExileArsenal" >> _vehicleClassname)) then
	{
		throw const!(TRADING_RESPONSE_INVALID_OBJECT_CLASS);
	};

	if !((count _pinCode) isEqualTo 4) then
	{
		throw const!(TRADING_RESPONSE_INVALID_PIN);
	};

	private _isShip = _vehicleClassname isKindOf "Ship";

	private _position = if (_isShip) then
	{
		[
			(getPosATL _playerObject), 100, 20
		] call ExileClient_util_world_findWaterPosition
	}
	else
	{
		(getPos _playerObject) findEmptyPosition [10, 250, _vehicleClassname]
	};

	if (_position isEqualTo []) then
	{
		throw const!(TRADING_RESPONSE_BIS_FNC_SAFE_POS_FAIL);
	};

	// Create le vehicle
	private _vehicleObject = [
		_vehicleClassname, _position, (random 360), !_isShip, _pinCode
	] call ExileServer_object_vehicle_createPersistentVehicle;

	// Set ownership
	_vehicleObject setVariable ["ExileOwnerUID", (getPlayerUID _playerObject)];
	_vehicleObject setVariable ["ExileIsLocked",0];
	_vehicleObject lock 0;

	// Save vehicle in database + update position/stats
	_vehicleObject call ExileServer_object_vehicle_database_insert;
	_vehicleObject call ExileServer_object_vehicle_database_update;

	// Update the database
	// For vehicles, we only redeem one vehicle at a time
	[_rewardCode, 1] call ESMs_system_reward_database_redeem;

	// Send response
	[
		_sessionID,
		"redeemVehicleResponse",
		[const!(TRADING_RESPONSE_OK), netId _vehicleObject]
	] call ExileServer_system_network_send_to;

	// extDB logging
	private _logging = getNumber(configFile >> "CfgSettings" >> "Logging" >> "traderLogging");
	if (_logging isEqualTo 1) then
	{
		_traderLog = format [
			"PLAYER: ( %1 ) %2 REDEEMED VEHICLE %3",
			getPlayerUID _playerObject,
			_playerObject,
			_vehicleClassname
		];

		ESM_DatabaseExtension callExtension format["1:TRADING:%1", _traderLog];
	};
}
catch
{
	private _responseCode = _exception;

	[
		_sessionID,
		"redeemVehicleResponse",
		[_responseCode, "", 0]
	] call ExileServer_system_network_send_to;
};

if !(isNull _playerObject) then
{
	_playerObject setVariable ["ExileMutex", false];
};

true
