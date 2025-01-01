/* ----------------------------------------------------------------------------
Description:
	UI for redeeming everything but vehicles. Basically a sightly modified trader dialog

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

class RscEsmItemRedeemDialog
{
	idd = 24037;
	onLoad = "uiNamespace setVariable ['RscEsmItemRedeemDialog', _this select 0]";
	onUnload = "call ESMc_gui_itemRedeemDialog_event_onUnload; uiNamespace setVariable ['RscEsmItemRedeemDialog', displayNull]";

	class controlsBackground
	{
		class DialogCaptionLeft: RscText
		{
			idc = 4000;

			x = -4 * GUI_GRID_W + GUI_GRID_X;
			y = -0.1 * GUI_GRID_H + GUI_GRID_Y;
			w = 17.5 * GUI_GRID_W;
			h = 1 * GUI_GRID_H;
			colorBackground[] = {0.1,0.1,0.1,1};
		};
		class DialogBackgroundLeft: RscText
		{
			idc = 2000;

			x = -4 * GUI_GRID_W + GUI_GRID_X;
			y = 1 * GUI_GRID_H + GUI_GRID_Y;
			w = 17.5 * GUI_GRID_W;
			h = 24 * GUI_GRID_H;
			colorBackground[] = {0.05,0.05,0.05,0.7};
		};
		class DialogBackgroundMiddle: RscText
		{
			idc = 2001;

			x = 14 * GUI_GRID_W + GUI_GRID_X;
			y = 1 * GUI_GRID_H + GUI_GRID_Y;
			w = 26 * GUI_GRID_W;
			h = 24 * GUI_GRID_H;
			colorBackground[] = {0.05,0.05,0.05,0.7};
		};
		class DialogCaptionMiddle: RscText
		{
			idc = 4001;

			text = "STORE";
			x = 14 * GUI_GRID_W + GUI_GRID_X;
			y = -0.1 * GUI_GRID_H + GUI_GRID_Y;
			w = 26 * GUI_GRID_W;
			h = 1 * GUI_GRID_H;
			colorBackground[] = {0.1,0.1,0.1,1};
		};
		class TextPlayerMoney: RscStructuredText
		{
			idc = 4002;

			text = "0";
			x = 5.5 * GUI_GRID_W + GUI_GRID_X;
			y = -0.1 * GUI_GRID_H + GUI_GRID_Y;
			w = 8 * GUI_GRID_W;
			h = 1 * GUI_GRID_H;
		};
		class CloseCross: RscActiveText
		{
			idc = 1032;
			action = "closeDialog 0;";
			style = 2096;
			color[] = {1,1,1,0.7};

			text = "\A3\Ui_f\data\GUI\Rsc\RscDisplayArcadeMap\icon_exit_cross_ca.paa";
			x = 38.8 * GUI_GRID_W + GUI_GRID_X;
			y = 0.2 * GUI_GRID_H + GUI_GRID_Y;
			w = 1 * GUI_GRID_W;
			h = 0.5 * GUI_GRID_H;
			colorText[] = {1,1,1,0.7};
			colorActive[] = {1,1,1,1};
			tooltip = "Close";
		};
		class InventoryDropDown: RscCombo
		{
			idc = 4004;
			onLBSelChanged = "_this call ExileClient_gui_traderDialog_event_onPlayerInventoryDropDownSelectionChanged";

			x = -3.5 * GUI_GRID_W + GUI_GRID_X;
			y = 1.5 * GUI_GRID_H + GUI_GRID_Y;
			w = 16.5 * GUI_GRID_W;
			h = 1 * GUI_GRID_H;
		};
		class InventoryListBox: RscExileItemListBox
		{
			idc = 4005;
			onLBSelChanged = "_this call ExileClient_gui_traderDialog_event_onPlayerInventoryListBoxSelectionChanged";

			x = -3.5 * GUI_GRID_W + GUI_GRID_X;
			y = 3 * GUI_GRID_H + GUI_GRID_Y;
			w = 16.5 * GUI_GRID_W;
			h = 20 * GUI_GRID_H;
			colorBackground[] = {1,1,1,0.1};
			sizeEx = 0.8 *    (   (   ((safezoneW / safezoneH) min 1.2) / 1.2) / 25) * GUI_GRID_H;
		};
		class CancelButton: RscButtonMenu
		{
			idc = 4006;
			action = "closeDialog 0;";

			text = "Cancel";
			x = 32.5 * GUI_GRID_W + GUI_GRID_X;
			y = 23.5 * GUI_GRID_H + GUI_GRID_Y;
			w = 7 * GUI_GRID_W;
			h = 1 * GUI_GRID_H;
			colorText[] = {1,1,1,1};
			colorBackground[] = {0,0,0,0.8};
		};
		class StoreDropDown: RscCombo
		{
			idc = 4008;
			onLBSelChanged = "_this call ExileClient_gui_traderDialog_event_onStoreDropDownSelectionChanged";

			x = 14.5 * GUI_GRID_W + GUI_GRID_X;
			y = 1.5 * GUI_GRID_H + GUI_GRID_Y;
			w = 12 * GUI_GRID_W;
			h = 1 * GUI_GRID_H;
		};
		class StoreListBox: RscExileItemListBox
		{
			idc = 4009;
			onLBSelChanged = "_this call ExileClient_gui_traderDialog_event_onStoreListBoxSelectionChanged";
			onLBDblClick = "_this call ExileClient_gui_traderDialog_event_onStoreListBoxItemDoubleClick";

			x = 14.5 * GUI_GRID_W + GUI_GRID_X;
			y = 3 * GUI_GRID_H + GUI_GRID_Y;
			w = 25 * GUI_GRID_W;
			h = 20 * GUI_GRID_H;
			colorBackground[] = {1,1,1,0.1};
			sizeEx = 0.8 *    (   (   ((safezoneW / safezoneH) min 1.2) / 1.2) / 25) * GUI_GRID_H;
		};
		class RedeemButton: RscButtonMenu
		{
			idc = 4010;
			onMouseButtonClick = "_this call ExileClient_gui_traderDialog_event_onPurchaseButtonClick";

			text = "Redeem";
			x = 23 * GUI_GRID_W + GUI_GRID_X;
			y = 23.5 * GUI_GRID_H + GUI_GRID_Y;
			w = 9 * GUI_GRID_W;
			h = 1 * GUI_GRID_H;
			colorText[] = {1,1,1,1};
			colorBackground[] = {0,0,0,0.8};
		};
		class PlayerLoadBackground: RscText
		{
			idc = 4043;

			x = -3.5 * GUI_GRID_W + GUI_GRID_X;
			y = 23.5 * GUI_GRID_H + GUI_GRID_Y;
			w = 16.5 * GUI_GRID_W;
			h = 1 * GUI_GRID_H;
			colorBackground[] = {0,0,0,0.5};
		};
		class PlayerLoadProgress: RscProgress
		{
			idc = 4012;

			x = -3.5 * GUI_GRID_W + GUI_GRID_X;
			y = 23.5 * GUI_GRID_H + GUI_GRID_Y;
			w = 16.5 * GUI_GRID_W;
			h = 1 * GUI_GRID_H;
			colorText[] = {1,1,1,0.25};
			colorBackground[] = {1,1,1,0.25};
		};
		class PlayerLoadLabel: RscText
		{
			idc = 4013;

			text = "LOAD";
			x = -3.5 * GUI_GRID_W + GUI_GRID_X;
			y = 23.5 * GUI_GRID_H + GUI_GRID_Y;
			w = 16.5 * GUI_GRID_W;
			h = 1 * GUI_GRID_H;
		};
		class PlayerLoadValue: RscStructuredText
		{
			idc = 4014;

			text = "100%";
			x = -3.5 * GUI_GRID_W + GUI_GRID_X;
			y = 23.5 * GUI_GRID_H + GUI_GRID_Y;
			w = 16.5 * GUI_GRID_W;
			h = 1 * GUI_GRID_H;
		};
		class FilterDropdown: RscCombo
		{
			idc = 4008;
			onLBSelChanged = "_this call ExileClient_gui_traderDialog_event_onStoreDropDownSelectionChanged";

			x = 27 * GUI_GRID_W + GUI_GRID_X;
			y = 1.5 * GUI_GRID_H + GUI_GRID_Y;
			w = 12.5 * GUI_GRID_W;
			h = 1 * GUI_GRID_H;
		};

	};
};
