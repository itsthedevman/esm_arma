/* ----------------------------------------------------------------------------
Function:
	ESMc_gui_vehicleRedeemDialog_event_onUnload

Description:
	None

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

// Moon Light adjustment
ExileClientMoonLight setLightBrightness 0.75;

// Destroy model box
call ExileClient_gui_modelBox_destroy;

// Show our hud
true call ExileClient_gui_hud_toggle;
