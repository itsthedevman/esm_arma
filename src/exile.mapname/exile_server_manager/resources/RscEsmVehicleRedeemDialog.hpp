/* ----------------------------------------------------------------------------
Description:
	UI for redeeming vehicles - this is a copy of the vehicle trader dialog

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

class RscEsmVehicleRedeemDialog
{
	idd = const!(IDD_VEHICLE_DIALOG);
	onLoad = "uiNamespace setVariable ['RscEsmVehicleRedeemDialog', _this select 0]";
	onUnload = "call ESMc_gui_vehicleRedeemDialog_event_onUnload; uiNamespace setVariable ['RscEsmVehicleRedeemDialog', displayNull]";

	class controlsBackground
	{
		class DialogBackground: RscEsmText
		{
			idc = const!(IDC_VEHICLE_DIALOG_BACKGROUND);

			x = -43.52 * const!(GUI_GRID_W) + const!(GUI_GRID_X);
			y = -9.32 * const!(GUI_GRID_H) + const!(GUI_GRID_Y);
			w = 26.0606 * const!(GUI_GRID_W);
			h = 30 * const!(GUI_GRID_H);
			colorBackground[] = {0.05,0.05,0.05,0.7};
		};
		class DialogTitle: RscEsmText
		{
			idc = const!(IDC_VEHICLE_DIALOG_TITLE);

			text = "Purchase Vehicle"; //--- ToDo: Localize;
			x = -41.89 * const!(GUI_GRID_W) + const!(GUI_GRID_X);
			y = -8.41 * const!(GUI_GRID_H) + const!(GUI_GRID_Y);
			w = 22.803 * const!(GUI_GRID_W);
			h = 1.81818 * const!(GUI_GRID_H);
			sizeEx = 1 * safezoneH / 25 * const!(GUI_GRID_H);
		};
		class CancelBackground: RscEsmText
		{
			idc = const!(IDC_VEHICLE_DIALOG_CANCEL_BACKGROUND);

			x = -43.52 * const!(GUI_GRID_W) + const!(GUI_GRID_X);
			y = 31.59 * const!(GUI_GRID_H) + const!(GUI_GRID_Y);
			w = 26.0606 * const!(GUI_GRID_W);
			h = 2.72727 * const!(GUI_GRID_H);
			colorBackground[] = {0.05,0.05,0.05,0.7};
		};
		class CategoryDropDown: RscEsmCombo
		{
			idc = const!(IDC_VEHICLE_DIALOG_CATEGORY_DROPDOWN);
			onLBSelChanged = "_this call ESMc_gui_vehicleRedeemDialog_event_onCategoryDropDownSelectionChanged";

			x = -41.89 * const!(GUI_GRID_W) + const!(GUI_GRID_X);
			y = -6.41 * const!(GUI_GRID_H) + const!(GUI_GRID_Y);
			w = 22.803 * const!(GUI_GRID_W);
			h = 1.27273 * const!(GUI_GRID_H);
		};
		class VehiclesListBox: RscEsmListBox
		{
			idc = const!(IDC_VEHICLE_DIALOG_VEHICLES_LIST);
			onLBSelChanged = "_this call ESMc_gui_vehicleRedeemDialog_event_onVehicleListBoxSelectionChanged";

			x = -41.89 * const!(GUI_GRID_W) + const!(GUI_GRID_X);
			y = -4.95 * const!(GUI_GRID_H) + const!(GUI_GRID_Y);
			w = 22.803 * const!(GUI_GRID_W);
			h = 12.7273 * const!(GUI_GRID_H);
			sizeEx = 0.8 *    (   (   ((safezoneW / safezoneH) min 1.2) / 1.2) / 25) * const!(GUI_GRID_H);
		};
		class ButtonRedeem: RscEsmButtonMenuOK
		{
			idc = const!(IDC_VEHICLE_DIALOG_REDEEM_BUTTON);
			onMouseButtonClick = "_this call ESMc_gui_vehicleRedeemDialog_event_onRedeemButtonClick";

			text = "Redeem now"; //--- ToDo: Localize;
			x = -41.89 * const!(GUI_GRID_W) + const!(GUI_GRID_X);
			y = 17.95 * const!(GUI_GRID_H) + const!(GUI_GRID_Y);
			w = 22.803 * const!(GUI_GRID_W);
			h = 1.81818 * const!(GUI_GRID_H);
			colorText[] = {1,1,1,1};
			colorBackground[] = {0,0,0,0.8};
			sizeEx = 0.75 * safezoneH / 25 * const!(GUI_GRID_H);
		};
		class CancelButton: RscEsmButtonMenuCancel
		{
			idc = const!(IDC_VEHICLE_DIALOG_CANCEL_BUTTON);
			action = "closeDialog 0";

			x = -41.89 * const!(GUI_GRID_W) + const!(GUI_GRID_X);
			y = 32.5 * const!(GUI_GRID_H) + const!(GUI_GRID_Y);
			w = 22.803 * const!(GUI_GRID_W);
			h = 0.909091 * const!(GUI_GRID_H);
			colorText[] = {1,1,1,1};
			colorBackground[] = {0,0,0,0.8};
		};
		class PinBox: RscEsmEdit
		{
			idc = const!(IDC_VEHICLE_DIALOG_PIN_BOX);
			onChar = "_this spawn ESMc_gui_vehicleRedeemDialog_event_onInputBoxChars";

			x = -41.89 * const!(GUI_GRID_W) + const!(GUI_GRID_X);
			y = 16.14 * const!(GUI_GRID_H) + const!(GUI_GRID_Y);
			w = 22.803 * const!(GUI_GRID_W);
			h = 1.63636 * const!(GUI_GRID_H);
			colorBackground[] = {0.05,0.05,0.05,0.7};
		};
		class PinText: RscEsmStructuredText
		{
			idc = const!(IDC_VEHICLE_DIALOG_PIN_TEXT);
			text = "Pin Code:"; //--- ToDo: Localize;
			x = -41.89 * const!(GUI_GRID_W) + const!(GUI_GRID_X);
			y = 14.86 * const!(GUI_GRID_H) + const!(GUI_GRID_Y);
			w = 22.803 * const!(GUI_GRID_W);
			h = 1.45455 * const!(GUI_GRID_H);
		};
		class Stat01Background: RscEsmText
		{
			idc = const!(IDC_VEHICLE_DIALOG_STAT01_BACKGROUND);

			x = -41.89 * const!(GUI_GRID_W) + const!(GUI_GRID_X);
			y = 8.86 * const!(GUI_GRID_H) + const!(GUI_GRID_Y);
			w = 22.803 * const!(GUI_GRID_W);
			h = 1.27273 * const!(GUI_GRID_H);
			colorBackground[] = {0,0,0,0.5};
		};
		class Stat01Progress: RscEsmProgress
		{
			idc = const!(IDC_VEHICLE_DIALOG_STAT01_PROGRESS);

			x = -41.89 * const!(GUI_GRID_W) + const!(GUI_GRID_X);
			y = 8.86 * const!(GUI_GRID_H) + const!(GUI_GRID_Y);
			w = 22.803 * const!(GUI_GRID_W);
			h = 1.27273 * const!(GUI_GRID_H);
			colorText[] = {1,1,1,0.25};
			colorBackground[] = {1,1,1,0.25};
		};
		class Stat01Label: RscEsmText
		{
			idc = const!(IDC_VEHICLE_DIALOG_STAT01_LABEL);

			x = -41.89 * const!(GUI_GRID_W) + const!(GUI_GRID_X);
			y = 8.86 * const!(GUI_GRID_H) + const!(GUI_GRID_Y);
			w = 22.803 * const!(GUI_GRID_W);
			h = 1.27273 * const!(GUI_GRID_H);
		};
		class Stat01Value: RscEsmStructuredText
		{
			idc = const!(IDC_VEHICLE_DIALOG_STAT01_VALUE);
			style = 1;

			x = -41.89 * const!(GUI_GRID_W) + const!(GUI_GRID_X);
			y = 8.86 * const!(GUI_GRID_H) + const!(GUI_GRID_Y);
			w = 22.803 * const!(GUI_GRID_W);
			h = 1.27273 * const!(GUI_GRID_H);
		};
		class Stat02Background: RscEsmText
		{
			idc = const!(IDC_VEHICLE_DIALOG_STAT02_BACKGROUND);

			x = -41.89 * const!(GUI_GRID_W) + const!(GUI_GRID_X);
			y = 10.32 * const!(GUI_GRID_H) + const!(GUI_GRID_Y);
			w = 22.803 * const!(GUI_GRID_W);
			h = 1.27273 * const!(GUI_GRID_H);
			colorBackground[] = {0,0,0,0.5};
		};
		class Stat02Progress: RscEsmProgress
		{
			idc = const!(IDC_VEHICLE_DIALOG_STAT02_PROGRESS);

			x = -41.89 * const!(GUI_GRID_W) + const!(GUI_GRID_X);
			y = 10.32 * const!(GUI_GRID_H) + const!(GUI_GRID_Y);
			w = 22.803 * const!(GUI_GRID_W);
			h = 1.27273 * const!(GUI_GRID_H);
			colorText[] = {1,1,1,0.25};
			colorBackground[] = {1,1,1,0.25};
		};
		class Stat02Label: RscEsmText
		{
			idc = const!(IDC_VEHICLE_DIALOG_STAT02_LABEL);

			x = -41.89 * const!(GUI_GRID_W) + const!(GUI_GRID_X);
			y = 10.32 * const!(GUI_GRID_H) + const!(GUI_GRID_Y);
			w = 22.803 * const!(GUI_GRID_W);
			h = 1.27273 * const!(GUI_GRID_H);
		};
		class Stat02Value: RscEsmStructuredText
		{
			idc = const!(IDC_VEHICLE_DIALOG_STAT02_VALUE);
			style = 1;

			x = -41.89 * const!(GUI_GRID_W) + const!(GUI_GRID_X);
			y = 10.32 * const!(GUI_GRID_H) + const!(GUI_GRID_Y);
			w = 22.803 * const!(GUI_GRID_W);
			h = 1.27273 * const!(GUI_GRID_H);
		};
		class Stat03Background: RscEsmText
		{
			idc = const!(IDC_VEHICLE_DIALOG_STAT03_BACKGROUND);

			x = -41.89 * const!(GUI_GRID_W) + const!(GUI_GRID_X);
			y = 11.77 * const!(GUI_GRID_H) + const!(GUI_GRID_Y);
			w = 22.803 * const!(GUI_GRID_W);
			h = 1.27273 * const!(GUI_GRID_H);
			colorBackground[] = {0,0,0,0.5};
		};
		class Stat03Progress: RscEsmProgress
		{
			idc = const!(IDC_VEHICLE_DIALOG_STAT03_PROGRESS);

			x = -41.89 * const!(GUI_GRID_W) + const!(GUI_GRID_X);
			y = 11.77 * const!(GUI_GRID_H) + const!(GUI_GRID_Y);
			w = 22.803 * const!(GUI_GRID_W);
			h = 1.27273 * const!(GUI_GRID_H);
			colorText[] = {1,1,1,0.25};
			colorBackground[] = {1,1,1,0.25};
		};
		class Stat03Label: RscEsmText
		{
			idc = const!(IDC_VEHICLE_DIALOG_STAT03_LABEL);

			x = -41.89 * const!(GUI_GRID_W) + const!(GUI_GRID_X);
			y = 11.77 * const!(GUI_GRID_H) + const!(GUI_GRID_Y);
			w = 22.803 * const!(GUI_GRID_W);
			h = 1.27273 * const!(GUI_GRID_H);
		};
		class Stat03Value: RscEsmStructuredText
		{
			idc = const!(IDC_VEHICLE_DIALOG_STAT03_VALUE);
			style = 1;

			x = -41.89 * const!(GUI_GRID_W) + const!(GUI_GRID_X);
			y = 11.77 * const!(GUI_GRID_H) + const!(GUI_GRID_Y);
			w = 22.803 * const!(GUI_GRID_W);
			h = 1.27273 * const!(GUI_GRID_H);
		};
		class Stat04Background: RscEsmText
		{
			idc = const!(IDC_VEHICLE_DIALOG_STAT04_BACKGROUND);

			x = -41.89 * const!(GUI_GRID_W) + const!(GUI_GRID_X);
			y = 13.23 * const!(GUI_GRID_H) + const!(GUI_GRID_Y);
			w = 22.803 * const!(GUI_GRID_W);
			h = 1.27273 * const!(GUI_GRID_H);
			colorBackground[] = {0,0,0,0.5};
		};
		class Stat04Progress: RscEsmProgress
		{
			idc = const!(IDC_VEHICLE_DIALOG_STAT04_PROGRESS);

			x = -41.89 * const!(GUI_GRID_W) + const!(GUI_GRID_X);
			y = 13.23 * const!(GUI_GRID_H) + const!(GUI_GRID_Y);
			w = 22.803 * const!(GUI_GRID_W);
			h = 1.27273 * const!(GUI_GRID_H);
			colorText[] = {1,1,1,0.25};
			colorBackground[] = {1,1,1,0.25};
		};
		class Stat04Label: RscEsmText
		{
			idc = const!(IDC_VEHICLE_DIALOG_STAT04_LABEL);

			x = -41.89 * const!(GUI_GRID_W) + const!(GUI_GRID_X);
			y = 13.23 * const!(GUI_GRID_H) + const!(GUI_GRID_Y);
			w = 22.803 * const!(GUI_GRID_W);
			h = 1.27273 * const!(GUI_GRID_H);
		};
		class Stat04Value: RscEsmStructuredText
		{
			idc = const!(IDC_VEHICLE_DIALOG_STAT04_VALUE);
			style = 1;

			x = -41.89 * const!(GUI_GRID_W) + const!(GUI_GRID_X);
			y = 13.23 * const!(GUI_GRID_H) + const!(GUI_GRID_Y);
			w = 22.803 * const!(GUI_GRID_W);
			h = 1.27273 * const!(GUI_GRID_H);
		};
	};
};
