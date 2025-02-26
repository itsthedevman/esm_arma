/* ----------------------------------------------------------------------------
Function:
	ESMc_gui_vehicleRedeemDialog_updateVehicleListBox

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

disableSerialization;

private _dialog = uiNameSpace getVariable ["RscEsmVehicleRedeemDialog", displayNull];
private _categoryClasses = _this;

if ((_categoryClasses select 0) isEqualTo "") then
{
	_categoryClasses = getArray(
		missionConfigFile >> "CfgTraders" >> ExileClientCurrentTrader >> "categories"
	);
};

// Clear the list
private _itemListControl = _dialog displayCtrl const!(IDC_VEHICLE_DIALOG_VEHICLES_LIST);
lbClear _itemListControl;

{
	private _categoryClass = _x;
	private _categoryVehicleClassNames = getArray(
		missionConfigFile >> "CfgTraderCategories" >> _categoryClass >> "items"
	);

	// Add the vehicles
	{
		private _className = _x;
		private _indexEntryIndex = _itemListControl lbAdd getText(
			configFile >> "CfgVehicles" >> _className >> "displayName"
		);

		_quality = getNumber(missionConfigFile >> "CfgExileArsenal" >> _className >> "quality");
		private _qualityColor = const!(COLOR_QUALITY_LEVEL_1);

		switch (_quality) do
		{
			case const!(QUALITY_LEVEL_2): 		 { _qualityColor = const!(COLOR_QUALITY_LEVEL_2); };
			case const!(QUALITY_LEVEL_3):		 { _qualityColor = const!(COLOR_QUALITY_LEVEL_3); };
			case const!(QUALITY_LEVEL_4):		 { _qualityColor = const!(COLOR_QUALITY_LEVEL_4); };
			case const!(QUALITY_LEVEL_5):		 { _qualityColor = const!(COLOR_QUALITY_LEVEL_5); };
			case const!(QUALITY_LEVEL_6):		 { _qualityColor = const!(COLOR_QUALITY_LEVEL_6); };
		};

		_itemListControl lbSetData [_indexEntryIndex, _className];
		_itemListControl lbSetColor [_indexEntryIndex, _qualityColor];
	}
	forEach _categoryVehicleClassNames;
}
forEach _categoryClasses;

lbSortByValue _itemListControl;

true
