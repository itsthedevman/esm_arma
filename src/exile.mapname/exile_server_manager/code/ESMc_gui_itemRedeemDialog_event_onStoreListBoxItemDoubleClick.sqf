/* ----------------------------------------------------------------------------
Function:
	ESMc_gui_itemRedeemDialog_event_onStoreListBoxItemDoubleClick

Description:
	Fires when the player double-clicks an item, which is a shortcut to buy an item without
	clicking the purchase button

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

private _storeListBox = _this select 0;
private _clickedOnIndex = _this select 1;

// Check if the purchase button is active and if so,
// simulate a click on that (owww, am i lazy)
private _dialog = uiNameSpace getVariable ["RscEsmItemRedeemDialog", displayNull];
private _redeemButton = _dialog displayCtrl const!(IDC_ITEM_DIALOG_REDEEM_BUTTON);

if (ctrlEnabled _redeemButton) then
{
	call ESMc_gui_itemRedeemDialog_event_onRedeemButtonClick;
};

true
