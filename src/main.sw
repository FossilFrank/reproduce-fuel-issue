contract;

use std::{
    address::Address,
    constants::ZERO_B256,
};


abi Token {
    #[storage(read, write)]fn initialize(mint_amount: u64, address: Address) -> u64;
    #[storage(read, write)]fn set_mint_amount(mint_amount: u64);
    #[storage(read)]fn get_mint_amount() -> u64;
}


storage {
    owner: Address = Address {
        value: ZERO_B256,
    },
    mint_amount: u64 = 0,
}

enum Error {
    CannotReinitialize: (),
}

impl Token for Contract {
    //////////////////////////////////////
    // Owner methods
    //////////////////////////////////////
    #[storage(read, write)]
    fn initialize(mint_amount: u64, address: Address) -> u64 {
        require(storage.owner.into() == ZERO_B256, Error::CannotReinitialize);
        // Start the next message to be signed
        // storage.owner = address;
        storage.mint_amount = mint_amount;
        storage.mint_amount
    }

    #[storage(read, write)]
    fn set_mint_amount(mint_amount: u64) {
        storage.mint_amount = mint_amount;
    }

    #[storage(read)]
    fn get_mint_amount() -> u64 {
        storage.mint_amount
    }

}
