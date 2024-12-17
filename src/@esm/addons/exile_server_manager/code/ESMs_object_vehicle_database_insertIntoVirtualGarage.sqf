/* ----------------------------------------------------------------------------
Function:
	ESMs_object_vehicle_database_insertIntoVirtualGarage

Description:
	Creates a new vehicle in the database and adds it to a territory's virtual garage

Parameters:
	_territory - [Object] The territory flag object
	_classname - [String] The vehicle's classname
	_pincode - [String] The pincode to assign to the vehicle
	_ownerUID - [String] The UID of the owner of the vehicle
	_nickname - [String] The VG nickname

Returns:
	Boolean - Did we successfully add the vehicle?

Examples:
	(begin example)

		[
			_territory,
			"Exile_Car_Hatchback_Green",
			"12345",
			getPlayerUID _playerObject,
			"Hatchy"
		]
		call ESMs_object_vehicle_addToVirtualGarage;

	(end)

Author:
	Exile Server Manager
	www.esmbot.com
	© 2018-current_year!() Bryan "WolfkillArcadia"

	This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License.
	To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/.
---------------------------------------------------------------------------- */

private _territory = _this select 0;
private _vehicleClass = _this select 1;
private _pinCode = _this select 2;
private _ownerUID = _this select 3;
private _nickname = _this select 4;

private _position = (getPos _territory) findEmptyPosition [10, 250, _vehicleClass];

if (empty?(_position)) exitWith { false };

_data =
[
	_vehicleClass,
	_ownerUID,
	true, // Locked?
	_position select 0, _position select 1, _position select 2,
	0, 0, 0, // vectorDir
	0, 0, 0, // vectorUp
	_pinCode
];

// Insert into the database
private _databaseMessage = ["insertVehicle", _data] call ExileServer_util_extDB2_createMessage;
private _vehicleID = _databaseMessage call ExileServer_system_database_query_insertSingle;

// Save the vehicle to the flag
private _storedVehicles = _territory getVariable ["ExileTerritoryStoredVehicles", []];

_storedVehicles pushBack [typeOf(_vehicleObject), _nickname];
_territory setVariable ["ExileTerritoryStoredVehicles", _storedVehicles, true];

// Insert into the VG
format[
	"storeVehicle:%1:%2:%3",
	_territory getVariable ["ExileDatabaseID", -1],
	_nickname,
	_vehicleID
] call ExileServer_system_database_query_fireAndForget;

true
