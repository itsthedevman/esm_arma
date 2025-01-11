///////////////////////////////////////////////////////////////////////////
// XM8 notification (flag steal in progress)
///////////////////////////////////////////////////////////////////////////
class flagStealStartedRequest
{
    module = "system_territory";

    parameters[] =
    {
        "OBJECT"	// Flag object
    };
};

///////////////////////////////////////////////////////////////////////////
// Loads all redeemables for a player
// Calls ESMs_system_reward_network_loadAllRequest
///////////////////////////////////////////////////////////////////////////
class rewardLoadAllRequest
{
	module = "esm_system";

	parameters[] =
	{
		// TODO
	};
};

class rewardLoadAllResponse
{
	module = "esm_system";

	parameters[] =
	{
		// TODO
	};
};

///////////////////////////////////////////////////////////////////////////
// Redeem item from reward system
// Calls ESMs_system_reward_network_redeemItemRequest
///////////////////////////////////////////////////////////////////////////
class rewardRedeemItemRequest
{
	module = "esm_system";

	parameters[] =
	{
		"STRING", 	// Item classname
		"STRING",	// Container type
		"STRING"	// Container net ID
	};
};

class rewardRedeemItemResponse
{
	module = "esm_system";

	parameters[] =
	{
		// TODO
	};
};


///////////////////////////////////////////////////////////////////////////
// Redeem vehicle from reward system
// Calls ESMs_system_reward_network_redeemVehicleRequest
///////////////////////////////////////////////////////////////////////////
class rewardRedeemVehicleRequest
{
	module = "esm_system";

	parameters[] =
	{
		"STRING",	// Vehicle classname
		"STRING"	// Pin code
	};
};

class rewardRedeemVehicleResponse
{
	module = "esm_system";

	parameters[] =
	{
		// TODO
	};
};
