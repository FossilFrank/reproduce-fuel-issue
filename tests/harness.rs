use fuels::{
    core::tx::{AssetId, ContractId},
    prelude::*,
    fuels_abigen::abigen,
};

///////////////////////////////
// Load the Token Contract abi
///////////////////////////////
abigen!(TestToken, "./out/debug/reproduce_issue-abi.json");

#[tokio::test]
async fn token_contract() {
    let num_wallets = 3;
    let num_coins = 1;
    // default initial amount 1000000000
    let initial_amount = 1000000000;
    let config = WalletsConfig::new(Some(num_wallets), Some(num_coins), Some(initial_amount));

    let wallets = launch_custom_provider_and_get_wallets(config, None).await;
    let wallet_owner = wallets.get(0).unwrap();

    ////////////////////////////////////////////////////////
    // Setup contracts
    ////////////////////////////////////////////////////////

    let token_contract_id = Contract::deploy(
        "./out/debug/reproduce_issue.bin",
        &wallet_owner,
        TxParameters::default(),
        StorageConfiguration::new(None, None),
    )
    .await
    .unwrap();
    let token_instance = TestToken::new(token_contract_id.clone(), wallet_owner.clone());

    ////////////////////////////////////////////////////////
    // Test Token Contract
    ////////////////////////////////////////////////////////

    // Get the contract ID and a handle to it
    let token_mint_amount = 10000;

    // Initialize contract
    let result = token_instance
        .methods()
        .initialize(token_mint_amount, wallet_owner.address().into())
        .call()
        .await
        .unwrap();
    assert_eq!(result.value, token_mint_amount);

    let result = token_instance
        .methods()
        .set_mint_amount(0)
        .call()
        .await
        .unwrap();

    // Verify the mint amount
    let mint_amount_contract = token_instance
        .methods()
        .get_mint_amount()
        .call()
        .await
        .unwrap();
    assert_eq!(mint_amount_contract.value, 0);

    // Verify update mint amount
    token_instance
        .methods()
        .set_mint_amount(1)
        .call()
        .await
        .unwrap();
    let mint_amount_contract = token_instance
        .methods()
        .get_mint_amount()
        .call()
        .await
        .unwrap();
    assert_eq!(mint_amount_contract.value, 1);
}
