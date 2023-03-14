contract;

dep stableswap;

use stableswap::coin_out;

abi MyContract {
    fn coin_out(coin_in: u64, scale_in: u64, scale_out: u64, reserve_in: u64, reserve_out: u64) -> u64;
    
}

impl MyContract for Contract {
    fn coin_out(coin_in: u64, scale_in: u64, scale_out: u64, reserve_in: u64, reserve_out: u64) -> u64 {
        coin_out(coin_in, scale_in, scale_out, reserve_in, reserve_out)
    }
}
