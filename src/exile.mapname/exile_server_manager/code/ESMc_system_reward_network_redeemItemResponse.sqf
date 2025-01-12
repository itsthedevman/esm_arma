/* ----------------------------------------------------------------------------
Function:
	ESMc_system_reward_network_redeemItemResponse

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

private _responseCode = _this select 0;
private _rewardCode = _this select 1;
private _rewardType = _this select 2;
private _itemClassname = _this select 3;
private _quantity  = _this select 4;
private _containerType = _this select 5;
private _containerNetID = _this select 6;

ExileClientIsWaitingForServerTradeResponse = false;

if (_responseCode isNotEqualTo const!(TRADING_RESPONSE_OK)) exitWith
{
	[
		"ErrorTitleAndText",
		[
			"Whoops!",
			format [
				"Something went really wrong. Please tell a server admin that you have tried to redeem a reward and tell them the code '%1'. Thank you!",
				_responseCode
			]
		]
	] call ExileClient_gui_toaster_addTemplateToast;
};

private _toastMessage = "";
switch (_rewardType) do
{
	case "poptabs":
	{
		_toastMessage = format [
			"+%1<img image='\exile_assets\texture\ui\poptab_inline_ca.paa' size='24'/>",
			_quantity
		];
	};

	case "respect":
	{
		_toastMessage = format ["+%1 respect", _quantity];
	};

	case "classname":
	{
		switch (_containerType) do
		{
			case const!(TRADE_CONTAINER_EQUIPMENT):
			{
				// When you buy a uniform/vest/backpack in to your equipment,
				// show the newest drop down options
				private _containersBefore = [uniform player, vest player, backpack player];

				{
					[player, _itemClassname] call ExileClient_util_playerCargo_add;
				}
				count _quantity;

				private _containersAfter = [uniform player, vest player, backpack player];

				if !(_containersAfter isEqualTo _containersBefore) then
				{
					call ESMc_gui_itemRedeemDialog_updateInventoryDropdown;
				};
			};

			case const!(TRADE_CONTAINER_UNIFORM):
			{
				{
					[
						(uniformContainer player), _itemClassname
					] call ExileClient_util_containerCargo_add;
				}
				count _quantity;
			};

			case const!(TRADE_CONTAINER_VEST):
			{
				{
					[
						(vestContainer player), _itemClassname
					] call ExileClient_util_containerCargo_add;
				}
				count _quantity;
			};

			case const!(TRADE_CONTAINER_BACKPACK):
			{
				{
					[
						(backpackContainer player), _itemClassname
					] call ExileClient_util_containerCargo_add;
				}
				count _quantity;
			};

			case const!(TRADE_CONTAINER_VEHICLE):
			{
				private _vehicle = objectFromNetId _containerNetID;

				{
					[_vehicle, _itemClassname] call ExileClient_util_containerCargo_add;
				}
				count _quantity;
			};
		};

		private _configName = _itemClassname call ExileClient_util_gear_getConfigNameByClassName;
		private _displayName = getText(
			configFile >> _configName >> _itemClassname >> "displayName"
		);

		_toastMessage = format ["+%1 %2", _quantity, _displayName];
	};
};

// Show notification
[
	"SuccessTitleAndText", ["Reward redeemed!", _toastMessage]
] call ExileClient_gui_toaster_addTemplateToast;

// Update the trader dialog
private _dialog = uiNameSpace getVariable ["RscEsmItemRedeemDialog", displayNull];

// Only update it when its still opened
if (_dialog isNotEqualTo displayNull) then
{
	// Update the player inventory + load
	call ESMc_gui_itemRedeemDialog_updateInventoryListBox;

	// Update player pop tabs
	call ESMc_gui_itemRedeemDialog_updatePlayerControls;

	// Update store list to show correct amount of tabs needed on tooltip
	call ESMc_gui_itemRedeemDialog_updateStoreListBox;

	// Simulate a click on the item again, so the whole "can i buy this?" logic triggers
	private _storeListBox = _dialog displayCtrl const!(IDC_ITEM_DIALOG_STORE_LIST);

	[
		_storeListBox,
		lbCurSel _storeListBox
	] call ESMc_gui_itemRedeemDialog_event_onStoreListBoxSelectionChanged;
};
