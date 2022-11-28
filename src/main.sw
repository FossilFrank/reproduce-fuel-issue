contract;

use std::{
    address::Address,
    auth::{msg_sender, AuthError},
    call_frames::contract_id,
    constants::ZERO_B256,
    context::balance_of,
    contract_id::ContractId,
    revert::require,
    token::{
        burn,
        mint,
        mint_to_address,
        transfer_to_address,
    },
};


abi Token {
    // Initialize contract
    #[storage(read, write)]fn initialize(mint_amount: u64, address: Address) -> u64;
    // Set mint amount for each address
    #[storage(read, write)]fn set_mint_amount(mint_amount: u64);
    // Get balance of the contract coins
    fn get_balance() -> u64;
    // Return the mint amount
    #[storage(read)]fn get_mint_amount() -> u64;
    // Get balance of a specified token on contract
    fn get_token_balance(asset_id: ContractId) -> u64;
    // Mint token coins
    #[storage(read)]fn mint_coins(mint_amount: u64);
    // Burn token coins
    #[storage(read)]fn burn_coins(burn_amount: u64);
    // Transfer a contract coins to a given output
    #[storage(read)]fn transfer_coins(coins: u64, address: Address);
    // Method called from address to mint coins
    #[storage(read, write)]fn mint();
    // Return the contract owner
    #[storage(read)]fn get_owner() -> Address;
    fn get_id() -> ContractId;
}


storage {
    owner: Address = Address {
        value: ZERO_B256,
    },
    mint_amount: u64 = 0,
    mint_list: StorageMap<Address, bool> = StorageMap {},
}

enum Error {
    AddressAlreadyMint: (),
    CannotReinitialize: (),
    MintIsClosed: (),
    NotOwner: (),
}

fn get_msg_sender_address_or_panic() -> Address {
    let sender: Result<Identity, AuthError> = msg_sender();
    if let Identity::Address(address) = sender.unwrap() {
        address
    } else {
        revert(0);
    }
}

#[storage(read)]
fn validate_owner() {
    let sender = get_msg_sender_address_or_panic();
    require(storage.owner == sender, Error::NotOwner);
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
        validate_owner();
        storage.mint_amount = mint_amount;
    }

    #[storage(read)]
    fn mint_coins(mint_amount: u64) {
        validate_owner();
        mint(mint_amount);
    }

    #[storage(read)]
    fn burn_coins(burn_amount: u64) {
        validate_owner();
        burn(burn_amount);
    }

    #[storage(read)]
    fn transfer_coins(coins: u64, address: Address) {
        validate_owner();
        transfer_to_address(coins, contract_id(), address);
    }

    //////////////////////////////////////
    // Mint public method
    //////////////////////////////////////
    #[storage(read, write)]
    fn mint() {
        require(storage.mint_amount > 0, Error::MintIsClosed);

        // Enable a address to mint only once
        let sender = get_msg_sender_address_or_panic();
        require(storage.owner == sender || storage.mint_list.get(sender) == false, Error::AddressAlreadyMint);

        storage.mint_list.insert(sender, true);
        mint_to_address(storage.mint_amount, sender);
    }

    //////////////////////////////////////
    // Read-Only methods
    //////////////////////////////////////
    fn get_id() -> ContractId {
        contract_id()
    }

    #[storage(read)]
    fn get_mint_amount() -> u64 {
        storage.mint_amount
    }

    fn get_balance() -> u64 {
        balance_of(contract_id(), contract_id())
    }

    fn get_token_balance(asset_id: ContractId) -> u64 {
        balance_of(asset_id, contract_id())
    }

    #[storage(read)]
    fn get_owner() -> Address {
        storage.owner
    }
}
