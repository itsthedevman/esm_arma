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
	idd = 24038;
	onLoad = "uiNamespace setVariable ['RscEsmVehicleRedeemDialog', _this select 0]";
	onUnload = "call ESMc_gui_vehicleRedeemDialog_event_onUnload; uiNamespace setVariable ['RscEsmVehicleRedeemDialog', displayNull]";

	class controlsBackground
	{
		class DialogBackground: RscText
		{
			idc = 1000;

			x = -43.52 * GUI_GRID_W + GUI_GRID_X;
			y = -9.32 * GUI_GRID_H + GUI_GRID_Y;
			w = 26.0606 * GUI_GRID_W;
			h = 30 * GUI_GRID_H;
			colorBackground[] = {0.05,0.05,0.05,0.7};
		};
		class DialogTitle: RscText
		{
			idc = 1001;

			text = "Purchase Vehicle"; //--- ToDo: Localize;
			x = -41.89 * GUI_GRID_W + GUI_GRID_X;
			y = -8.41 * GUI_GRID_H + GUI_GRID_Y;
			w = 22.803 * GUI_GRID_W;
			h = 1.81818 * GUI_GRID_H;
			sizeEx = 1 * safezoneH / 25 * GUI_GRID_H;
		};
		class CancelBackground: RscText
		{
			idc = 1006;

			x = -43.52 * GUI_GRID_W + GUI_GRID_X;
			y = 31.59 * GUI_GRID_H + GUI_GRID_Y;
			w = 26.0606 * GUI_GRID_W;
			h = 2.72727 * GUI_GRID_H;
			colorBackground[] = {0.05,0.05,0.05,0.7};
		};
		class CategoryDropDown: RscCombo
		{
			idc = 4000;
			onLBSelChanged = "_this call ESMc_gui_vehicleRedeemDialog_event_onCategoryDropDownSelectionChanged";

			x = -41.89 * GUI_GRID_W + GUI_GRID_X;
			y = -6.41 * GUI_GRID_H + GUI_GRID_Y;
			w = 22.803 * GUI_GRID_W;
			h = 1.27273 * GUI_GRID_H;
		};
		class VehiclesListBox: RscExileItemListBox
		{
			idc = 4001;
			onLBSelChanged = "_this call ESMc_gui_vehicleRedeemDialog_event_onVehicleListBoxSelectionChanged";

			x = -41.89 * GUI_GRID_W + GUI_GRID_X;
			y = -4.95 * GUI_GRID_H + GUI_GRID_Y;
			w = 22.803 * GUI_GRID_W;
			h = 12.7273 * GUI_GRID_H;
			sizeEx = 0.8 *    (   (   ((safezoneW / safezoneH) min 1.2) / 1.2) / 25) * GUI_GRID_H;
		};
		class ButtonPurchase: RscButtonMenuOK
		{
			idc = 4002;
			onMouseButtonClick = "_this call ESMc_gui_vehicleRedeemDialog_event_onPurchaseButtonClick";

			text = "Purchase now"; //--- ToDo: Localize;
			x = -41.89 * GUI_GRID_W + GUI_GRID_X;
			y = 17.95 * GUI_GRID_H + GUI_GRID_Y;
			w = 22.803 * GUI_GRID_W;
			h = 1.81818 * GUI_GRID_H;
			colorText[] = {1,1,1,1};
			colorBackground[] = {0,0,0,0.8};
			sizeEx = 0.75 * safezoneH / 25 * GUI_GRID_H;
		};
		class CancelButton: RscButtonMenuCancel
		{
			idc = 4006;
			action = "closeDialog 0";

			x = -41.89 * GUI_GRID_W + GUI_GRID_X;
			y = 32.5 * GUI_GRID_H + GUI_GRID_Y;
			w = 22.803 * GUI_GRID_W;
			h = 0.909091 * GUI_GRID_H;
			colorText[] = {1,1,1,1};
			colorBackground[] = {0,0,0,0.8};
		};
		class PinBox: RscEdit
		{
			idc = 4008;
			onChar = "_this spawn ESMc_gui_vehicleRedeemDialog_event_onInputBoxChars";

			x = -41.89 * GUI_GRID_W + GUI_GRID_X;
			y = 16.14 * GUI_GRID_H + GUI_GRID_Y;
			w = 22.803 * GUI_GRID_W;
			h = 1.63636 * GUI_GRID_H;
			colorBackground[] = {0.05,0.05,0.05,0.7};
		};
		class PinText: RscStructuredText
		{
			idc = 1100;
			text = "Pin Code:"; //--- ToDo: Localize;
			x = -41.89 * GUI_GRID_W + GUI_GRID_X;
			y = 14.86 * GUI_GRID_H + GUI_GRID_Y;
			w = 22.803 * GUI_GRID_W;
			h = 1.45455 * GUI_GRID_H;
		};
		class Stat01Background: RscText
		{
			idc = 6000;

			x = -41.89 * GUI_GRID_W + GUI_GRID_X;
			y = 8.86 * GUI_GRID_H + GUI_GRID_Y;
			w = 22.803 * GUI_GRID_W;
			h = 1.27273 * GUI_GRID_H;
			colorBackground[] = {0,0,0,0.5};
		};
		class Stat01Progress: RscProgress
		{
			idc = 6001;

			x = -41.89 * GUI_GRID_W + GUI_GRID_X;
			y = 8.86 * GUI_GRID_H + GUI_GRID_Y;
			w = 22.803 * GUI_GRID_W;
			h = 1.27273 * GUI_GRID_H;
			colorText[] = {1,1,1,0.25};
			colorBackground[] = {1,1,1,0.25};
		};
		class Stat01Label: RscText
		{
			idc = 6002;

			x = -41.89 * GUI_GRID_W + GUI_GRID_X;
			y = 8.86 * GUI_GRID_H + GUI_GRID_Y;
			w = 22.803 * GUI_GRID_W;
			h = 1.27273 * GUI_GRID_H;
		};
		class Stat01Value: RscStructuredText
		{
			idc = 6003;
			style = 1;

			x = -41.89 * GUI_GRID_W + GUI_GRID_X;
			y = 8.86 * GUI_GRID_H + GUI_GRID_Y;
			w = 22.803 * GUI_GRID_W;
			h = 1.27273 * GUI_GRID_H;
		};
		class Stat02Background: RscText
		{
			idc = 6004;

			x = -41.89 * GUI_GRID_W + GUI_GRID_X;
			y = 10.32 * GUI_GRID_H + GUI_GRID_Y;
			w = 22.803 * GUI_GRID_W;
			h = 1.27273 * GUI_GRID_H;
			colorBackground[] = {0,0,0,0.5};
		};
		class Stat02Progress: RscProgress
		{
			idc = 6005;

			x = -41.89 * GUI_GRID_W + GUI_GRID_X;
			y = 10.32 * GUI_GRID_H + GUI_GRID_Y;
			w = 22.803 * GUI_GRID_W;
			h = 1.27273 * GUI_GRID_H;
			colorText[] = {1,1,1,0.25};
			colorBackground[] = {1,1,1,0.25};
		};
		class Stat02Label: RscText
		{
			idc = 6006;

			x = -41.89 * GUI_GRID_W + GUI_GRID_X;
			y = 10.32 * GUI_GRID_H + GUI_GRID_Y;
			w = 22.803 * GUI_GRID_W;
			h = 1.27273 * GUI_GRID_H;
		};
		class Stat02Value: RscStructuredText
		{
			idc = 6007;
			style = 1;

			x = -41.89 * GUI_GRID_W + GUI_GRID_X;
			y = 10.32 * GUI_GRID_H + GUI_GRID_Y;
			w = 22.803 * GUI_GRID_W;
			h = 1.27273 * GUI_GRID_H;
		};
		class Stat03Background: RscText
		{
			idc = 6008;

			x = -41.89 * GUI_GRID_W + GUI_GRID_X;
			y = 11.77 * GUI_GRID_H + GUI_GRID_Y;
			w = 22.803 * GUI_GRID_W;
			h = 1.27273 * GUI_GRID_H;
			colorBackground[] = {0,0,0,0.5};
		};
		class Stat03Progress: RscProgress
		{
			idc = 6009;

			x = -41.89 * GUI_GRID_W + GUI_GRID_X;
			y = 11.77 * GUI_GRID_H + GUI_GRID_Y;
			w = 22.803 * GUI_GRID_W;
			h = 1.27273 * GUI_GRID_H;
			colorText[] = {1,1,1,0.25};
			colorBackground[] = {1,1,1,0.25};
		};
		class Stat03Label: RscText
		{
			idc = 6010;

			x = -41.89 * GUI_GRID_W + GUI_GRID_X;
			y = 11.77 * GUI_GRID_H + GUI_GRID_Y;
			w = 22.803 * GUI_GRID_W;
			h = 1.27273 * GUI_GRID_H;
		};
		class Stat03Value: RscStructuredText
		{
			idc = 6011;
			style = 1;

			x = -41.89 * GUI_GRID_W + GUI_GRID_X;
			y = 11.77 * GUI_GRID_H + GUI_GRID_Y;
			w = 22.803 * GUI_GRID_W;
			h = 1.27273 * GUI_GRID_H;
		};
		class Stat04Background: RscText
		{
			idc = 6012;

			x = -41.89 * GUI_GRID_W + GUI_GRID_X;
			y = 13.23 * GUI_GRID_H + GUI_GRID_Y;
			w = 22.803 * GUI_GRID_W;
			h = 1.27273 * GUI_GRID_H;
			colorBackground[] = {0,0,0,0.5};
		};
		class Stat04Progress: RscProgress
		{
			idc = 6013;

			x = -41.89 * GUI_GRID_W + GUI_GRID_X;
			y = 13.23 * GUI_GRID_H + GUI_GRID_Y;
			w = 22.803 * GUI_GRID_W;
			h = 1.27273 * GUI_GRID_H;
			colorText[] = {1,1,1,0.25};
			colorBackground[] = {1,1,1,0.25};
		};
		class Stat04Label: RscText
		{
			idc = 6014;

			x = -41.89 * GUI_GRID_W + GUI_GRID_X;
			y = 13.23 * GUI_GRID_H + GUI_GRID_Y;
			w = 22.803 * GUI_GRID_W;
			h = 1.27273 * GUI_GRID_H;
		};
		class Stat04Value: RscStructuredText
		{
			idc = 6015;
			style = 1;

			x = -41.89 * GUI_GRID_W + GUI_GRID_X;
			y = 13.23 * GUI_GRID_H + GUI_GRID_Y;
			w = 22.803 * GUI_GRID_W;
			h = 1.27273 * GUI_GRID_H;
		};
	};
};
