/* ----------------------------------------------------------------------------
Function:
	ESMc_gui_vehicleRedeemDialog_event_onCategoryDropDownSelectionChanged

Description:


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

disableSerialization;

private _comboBox = _this select 0;
private _index = _this select 1;

private _categoryClass = _comboBox lbData _index;

[_categoryClass] call ESMc_gui_vehicleRedeemDialog_updateVehicleListBox;

true
