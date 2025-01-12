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
		"STRING", 	// Reward code
		"STRING",	// Container type
		"STRING"	// Container net ID
	};
};

class rewardRedeemItemResponse
{
	module = "esm_system";

	parameters[] =
	{
		"SCALAR", 	// Response code
		"STRING", 	// Reward code
		"STRING", 	// Reward type
		"STRING", 	// Item classname if reward type is "classname"
		"SCALAR", 	// Quantity
		"SCALAR", 	// Container type
		"STRING" 	// NetID of vehicle if container type is "vehicle"

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
