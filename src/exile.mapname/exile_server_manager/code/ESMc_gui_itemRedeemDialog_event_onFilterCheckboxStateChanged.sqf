/*
	Fires when the player chooses between weapon filter modes in the trader dialog.
	Does not take the state into consideration, but updates the GUI.
*/

// Update the store inventory and filter to items that fit to our weapon
call ExileClient_gui_traderDialog_updateStoreListBox;

true