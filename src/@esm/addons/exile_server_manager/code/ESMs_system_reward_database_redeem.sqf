/* ----------------------------------------------------------------------------
Function:
	ESMs_system_reward_database_redeem

Description:


Parameters:
	_this select 0 - [String] The reward code
	_this select 1 - [Scalar] The quantity redeemed

Returns:
	Nothing

Examples:
	(begin example)

		[_rewardCode, _quantity] call ESMs_system_reward_database_redeem;

	(end)

Author:
	Exile Server Manager
	www.esmbot.com
	© 2018-current_year!() Bryan "WolfkillArcadia"

	This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License.
	To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/.
---------------------------------------------------------------------------- */

["redeemReward", _this select 0, _this select 1] call ESMs_system_extension_call;
