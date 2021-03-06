package emission


import "fmt"
import "math/big"
import "github.com/deroproject/derosuite/config"



// the logic is same as cryptonote_basic_impl.cpp

// this file controls the logic for emission of coins at each height
// calculates block reward

func GetBlockReward(bl_median_size uint64,
	bl_current_size uint64,
	already_generated_coins uint64,
	hard_fork_version uint64,
	fee uint64) (reward uint64) {

	target := config.COIN_DIFFICULTY_TARGET
	target_minutes := target / 60
	emission_speed_factor := config.COIN_EMISSION_SPEED_FACTOR - (target_minutes - 1)
	// handle special cases
	switch already_generated_coins {
	case 0:
		reward = 1000000000000 // give 1 DERO to genesis, but we gave 35 due to a silly typo, so continue as is
		return reward
	case 1000000000000:
		reward = 2000000 * 1000000000000 // give the developers initial premine, while keeping the, into account and respecting transparancy
		return reward
	}

	base_reward := (config.COIN_MONEY_SUPPLY - already_generated_coins) >> emission_speed_factor
	if base_reward < (config.COIN_FINAL_SUBSIDY_PER_MINUTE * target_minutes) {
		base_reward = config.COIN_FINAL_SUBSIDY_PER_MINUTE * target_minutes
	}

	//full_reward_zone = get_min_block_size(version);
	full_reward_zone := config.CRYPTONOTE_BLOCK_GRANTED_FULL_REWARD_ZONE

	if bl_median_size < full_reward_zone {
		bl_median_size = full_reward_zone
	}

	if bl_current_size <= bl_median_size {
		reward = base_reward

		fmt.Printf("Retunring base reward\n")
		return reward
	}

	// block is bigger than median size , we must calculate it
	if bl_current_size > 2*bl_median_size {
		//MERROR("Block cumulative size is too big: " << current_block_size << ", expected less than " << 2 * median_size);
		panic("Block size is too big\n")
		return
	}

	//panic("This mode of base reward calculation is not yet implemented\n")

	multiplicand := (2 * bl_median_size) - bl_current_size
	multiplicand = multiplicand * bl_current_size

	var big_base_reward, big_multiplicand, big_product, big_reward, big_median_size big.Int

	big_median_size.SetUint64(bl_median_size)
	big_base_reward.SetUint64(base_reward)
	big_multiplicand.SetUint64(multiplicand)

	big_product.Mul(&big_base_reward, &big_multiplicand)
	big_reward.Div(&big_product, &big_median_size)
	big_product.Set(&big_reward)
	big_reward.Div(&big_product, &big_median_size)

	// lower 64 bits contains the reward

	if !big_reward.IsUint64() {
		panic("GetBlockReward has issues\n")
	}

	reward_lo := big_reward.Uint64()

	if reward_lo > base_reward {
		panic("Reward must be less than base reward\n")
	}

	return reward_lo
}
