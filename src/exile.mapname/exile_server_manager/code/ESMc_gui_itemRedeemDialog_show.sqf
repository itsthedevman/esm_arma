/* ----------------------------------------------------------------------------
Function:
	ESMc_gui_itemRedeemDialog_show

Description:
	Shows the item redemption dialog

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

// Show the dialog
createDialog "RscEsmItemRedeemDialog";

// Ensure it is there
waitUntil { !isNull findDisplay const!(IDD_ITEM_DIALOG) };

private _dialog = uiNameSpace getVariable ["RscEsmItemRedeemDialog", displayNull];
uiNameSpace setVariable ["RscRedeemDialogIsInitialized", false];

// Move away the focus of the abort button
ctrlSetFocus (_dialog displayCtrl const!(IDC_ITEM_DIALOG_CAPTION_LEFT));

// Disable redemption button by default
(_dialog displayCtrl const!(IDC_ITEM_DIALOG_REDEEM_BUTTON)) ctrlEnable false;

true call ExileClient_gui_postProcessing_toggleDialogBackgroundBlur;

nil call ESMc_gui_itemRedeemDialog_updatePlayerControls;
nil call ESMc_gui_itemRedeemDialog_updateInventoryDropdown;
nil call ESMc_gui_itemRedeemDialog_updateInventoryListBox;
nil call ESMc_gui_itemRedeemDialog_updateStoreDropdown;
nil call ESMc_gui_itemRedeemDialog_updateStoreListBox;

uiNameSpace setVariable ["RscRedeemDialogIsInitialized", true];

true
