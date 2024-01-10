module my_addrx::property_coin {
    use aptos_framework::coin::{Self, Coin};
    use aptos_framework::timestamp;
    use aptos_framework::account;
    use aptos_framework::account::SignerCapability;
    use aptos_std::event::{Self, EventHandle};
    use std::option;
    use std::signer;
    use std::string;
    use std::error;

    //Error codes
    ///Permission denied
    const EPERMISSION_DENIED: u64 = 1001;
    ///Token capabilities already exist
    const ETOKEN_CAPABILITIES_EXIST: u64 = 1003;
    ///Invalid token owner
    const EINVALID_TOKEN_OWNER: u64 = 1004;

    
    //Constants
    const PROPERTY_TOKEN_SEED: vector<u8> = b"MARKETPLACE:RESOURCE_ACCOUNT";
    
    //Structs
    struct PropertyToken {}

    struct PropertyTokenCapabilities has key {
        burn_capability: coin::BurnCapability<PropertyToken>,
        freeze_capability: coin::FreezeCapability<PropertyToken>,
        mint_capability: coin::MintCapability<PropertyToken>,
    }

    struct TokenCapability has key {
        token_capability: SignerCapability,
    }

    struct InitializePropertyTokenEvent has drop, store {
        account: address,
        name: string::String,
        symbol: string::String,
        decimals: u8,
        monitor_supply: bool,
        timestamp: u64,
    }

    struct MintPropertyTokenEvent has drop, store {
        owner_addr: address,
        user_addr: address,
        amount: u64,
        timestamp: u64,
    }

    struct TransferPropertyTokenEvent has drop, store {
        from_addr: address,
        to_addr: address,
        amount: u64,
        timestamp: u64,
    }

    struct FreezeOrUnfreezeAccountEvent has drop, store {
        account: address,
        freeze_account: address,
        freeze: bool,
        timestamp: u64,
    }

    struct BurnAccountEvent has drop, store {
        account: address,
        burn_account: address,
        amount: u64,
        timestamp: u64,
    }

    struct RegisterPropertyTokenEvent has drop, store {
        account: address,
        timestamp: u64,
    }

    struct PropertyTokenEvents has key {
        initialize_property_token_event: EventHandle<InitializePropertyTokenEvent>,
        mint_property_token_event: EventHandle<MintPropertyTokenEvent>,
        transfer_property_token_event: EventHandle<TransferPropertyTokenEvent>,
        freeze_or_unfreeze_account_event: EventHandle<FreezeOrUnfreezeAccountEvent>,
        burn_account_event: EventHandle<BurnAccountEvent>,
        register_property_token_event: EventHandle<RegisterPropertyTokenEvent>,
    }

    /**
     * @notice Get the balance of the property token for a given owner address.
     * @param owner The address of the token owner.
     * @return The balance of the property token.
     */

    #[view]
    public fun balance(owner: address): u64 {
        coin::balance<PropertyToken>(owner)
    }

    /**
     * @notice Get the name of the property token.
     * @return The name of the property token.
     */
    #[view]
    public fun name(): string::String {
        coin::name<PropertyToken>()
    }
    /**
     * @notice Get the symbol of the property token.
     * @return The symbol of the property token.
     */
    #[view]
    public fun symbol(): string::String {
        coin::symbol<PropertyToken>()
    }

    /**
     * @notice Get the number of decimal places used for the property token.
     * @return The number of decimal places.
     */

    #[view]
    public fun decimals(): u8 {
        coin::decimals<PropertyToken>()
    }
    /**
     * @notice Get the total supply of the property token.
     * @return The total supply of the property token.
     */

    #[view]
    public fun totalSupply(): u128 {
        let x = coin::supply<PropertyToken>();
        option::extract(&mut x)
    }

     /**
     * @notice Initialize the property token with the provided parameters.
     * @param account The signer account initializing the token.
     * @param name The name of the property token.
     * @param symbol The symbol of the property token.
     * @param decimals The number of decimal places for the property token.
     * @param monitor_supply Whether to monitor the token supply.
     */

    public entry fun initialize_property_token(
        account: &signer,
        name: string::String,
        symbol: string::String,
        decimals: u8,
        monitor_supply: bool,
    ) acquires PropertyTokenEvents {
        let account_addr: address = signer::address_of(account);

        assert!(account_addr == @my_addrx, error::permission_denied(EPERMISSION_DENIED));

        let (token_signer, token_capability): (signer, SignerCapability) =
            account::create_resource_account(account, PROPERTY_TOKEN_SEED);

        let token_addr: address = signer::address_of(&token_signer);
        let (burn_cap, freeze_cap, mint_cap): (
            coin::BurnCapability<PropertyToken>,
            coin::FreezeCapability<PropertyToken>,
            coin::MintCapability<PropertyToken>,
        ) = coin::initialize<PropertyToken>(account, name, symbol, decimals, monitor_supply);

        assert!(
            !exists<TokenCapability>(token_addr),
            error::already_exists(ETOKEN_CAPABILITIES_EXIST)
        );
        move_to(
            &token_signer,
            TokenCapability {
                token_capability: token_capability,
            },
        );

        assert!(
            !exists<PropertyTokenCapabilities>(token_addr),
            error::already_exists(ETOKEN_CAPABILITIES_EXIST)
        );
        move_to(
            &token_signer,
            PropertyTokenCapabilities {
                burn_capability: burn_cap,
                freeze_capability: freeze_cap,
                mint_capability: mint_cap,
            },
        );

        if (!exists<PropertyTokenEvents>(token_addr)) {
            move_to(
                &token_signer,
                PropertyTokenEvents {
                    initialize_property_token_event: account::new_event_handle(&token_signer),
                    mint_property_token_event: account::new_event_handle(&token_signer),
                    transfer_property_token_event: account::new_event_handle(&token_signer),
                    freeze_or_unfreeze_account_event: account::new_event_handle(&token_signer),
                    burn_account_event: account::new_event_handle(&token_signer),
                    register_property_token_event: account::new_event_handle(&token_signer),
                },
            );
        };

        coin::register<PropertyToken>(account);

        let event_data: &mut PropertyTokenEvents = borrow_global_mut<PropertyTokenEvents>(token_addr);

        event::emit_event<RegisterPropertyTokenEvent>(
            &mut event_data.register_property_token_event,
            RegisterPropertyTokenEvent {
                account: account_addr,
                timestamp: timestamp::now_seconds(),
            },
        );

        event::emit_event<InitializePropertyTokenEvent>(
            &mut event_data.initialize_property_token_event,
            InitializePropertyTokenEvent {
                account: account_addr,
                name,
                symbol,
                decimals,
                monitor_supply,
                timestamp: timestamp::now_seconds(),
            },
        )
    }
     /**
     * @notice Register the property token for the specified account.
     * @param account The signer account registering the token.
     */
    public entry fun register_property_token(account: &signer) acquires PropertyTokenEvents {
        let account_addr = signer::address_of(account);
        coin::register<PropertyToken>(account);
        let token_addr: address = account::create_resource_address(&@my_addrx, PROPERTY_TOKEN_SEED);

        let event_data: &mut PropertyTokenEvents = borrow_global_mut<PropertyTokenEvents>(token_addr);

        event::emit_event<RegisterPropertyTokenEvent>(
            &mut event_data.register_property_token_event,
            RegisterPropertyTokenEvent {
                account: account_addr,
                timestamp: timestamp::now_seconds(),
            },
        )
    }

     /**
     * @notice Mint property tokens and assign them to a user.
     * @param account The signer account minting the tokens.
     * @param user_addr The address of the user receiving the tokens.
     * @param amount The amount of tokens to mint.
     */

    public entry fun mint_property_token(account: &signer, user_addr: address, amount: u64) acquires PropertyTokenCapabilities, PropertyTokenEvents {
        let token_owner: address = signer::address_of(account);

        assert!(
            token_owner == @my_addrx,
            error::invalid_state(EINVALID_TOKEN_OWNER)
        );

        let token_addr: address = account::create_resource_address(&@my_addrx, PROPERTY_TOKEN_SEED);
        let mint_cap = &borrow_global<PropertyTokenCapabilities>(token_addr).mint_capability;
        let coin: Coin<PropertyToken> = coin::mint<PropertyToken>(amount, mint_cap);

        coin::deposit<PropertyToken>(user_addr, coin);

        let event_data: &mut PropertyTokenEvents = borrow_global_mut<PropertyTokenEvents>(token_addr);

        event::emit_event<MintPropertyTokenEvent>(
            &mut event_data.mint_property_token_event,
            MintPropertyTokenEvent {
                owner_addr: token_owner,
                user_addr,
                amount,
                timestamp: timestamp::now_seconds(),
            },
        )
    }

     /**
     * @notice Transfer property tokens from one address to another.
     * @param from The signer account transferring the tokens.
     * @param to_addr The address of the recipient.
     * @param amount The amount of tokens to transfer.
     */
    public entry fun transfer_property_token(from: &signer, to_addr: address, amount: u64) acquires PropertyTokenEvents {
        let from_addr = signer::address_of(from);
        coin::transfer<PropertyToken>(from, to_addr, amount);

        let token_addr: address = account::create_resource_address(&@my_addrx, PROPERTY_TOKEN_SEED);
        let event_data: &mut PropertyTokenEvents = borrow_global_mut<PropertyTokenEvents>(token_addr);

        event::emit_event<TransferPropertyTokenEvent>(
            &mut event_data.transfer_property_token_event,
            TransferPropertyTokenEvent {
                from_addr,
                to_addr,
                amount,
                timestamp: timestamp::now_seconds(),
            },
        )
    }

      /**
     * @notice Freeze or unfreeze the specified account.
     * @param account The signer account freezing or unfreezing the account.
     * @param freeze_account The address of the account to be frozen or unfrozen.
     * @param freeze A boolean indicating whether to freeze or unfreeze the account.
     */

    public entry fun freeze_account(account: &signer, freeze_account: address, freeze: bool) acquires PropertyTokenCapabilities, PropertyTokenEvents {
        let account_addr: address = signer::address_of(account);

        assert!(
            account_addr == @my_addrx,
            error::invalid_state(EINVALID_TOKEN_OWNER)
        );

        let token_addr: address = account::create_resource_address(&@my_addrx, PROPERTY_TOKEN_SEED);
        let freeze_cap: &coin::FreezeCapability<PropertyToken> = &borrow_global<PropertyTokenCapabilities>(token_addr).freeze_capability;
        let event_data: &mut PropertyTokenEvents = borrow_global_mut<PropertyTokenEvents>(token_addr);
        if (freeze) {
            coin::freeze_coin_store<PropertyToken>(freeze_account, freeze_cap);

            event::emit_event<FreezeOrUnfreezeAccountEvent>(
                &mut event_data.freeze_or_unfreeze_account_event,
                FreezeOrUnfreezeAccountEvent {
                    account: account_addr,
                    freeze_account,
                    freeze,
                    timestamp: timestamp::now_seconds(),
                },
            )
        } else {
            coin::unfreeze_coin_store<PropertyToken>(freeze_account, freeze_cap);

            event::emit_event<FreezeOrUnfreezeAccountEvent>(
                &mut event_data.freeze_or_unfreeze_account_event,
                FreezeOrUnfreezeAccountEvent {
                    account: account_addr,
                    freeze_account,
                    freeze,
                    timestamp: timestamp::now_seconds(),
                },
            )
        }
    }

     /**
     * @notice Burn property tokens owned by the specified account.
     * @param account The signer account burning the tokens.
     * @param amount The amount of tokens to burn.
     */

    public entry fun pt_burn(account: &signer, amount: u64) acquires PropertyTokenEvents, PropertyTokenCapabilities {
        let account_addr: address = signer::address_of(account);

        assert!(
            account_addr == @my_addrx,
            error::invalid_state(EINVALID_TOKEN_OWNER)
        );

        let token_addr = account::create_resource_address(&@my_addrx, PROPERTY_TOKEN_SEED);

        let burn_cap = &borrow_global<PropertyTokenCapabilities>(token_addr).burn_capability;

        let coin: Coin<PropertyToken> = coin::withdraw(account, amount);
        coin::burn(coin, burn_cap);

        let event_data: &mut PropertyTokenEvents = borrow_global_mut<PropertyTokenEvents>(token_addr);

        event::emit_event<BurnAccountEvent>(
            &mut event_data.burn_account_event,
            BurnAccountEvent {
                account: account_addr,
                burn_account: account_addr,
                amount,
                timestamp: timestamp::now_seconds(),
            },
        )
    }

     /**
     * @notice Burn property tokens from the specified user's account.
     * @param account The signer account burning the tokens.
     * @param user_addr The address of the user whose tokens are being burned.
     * @param amount The amount of tokens to burn.
     */

    public entry fun pt_burn_from(account: &signer, user_addr: address, amount: u64) acquires PropertyTokenEvents, PropertyTokenCapabilities {
        let account_addr: address = signer::address_of(account);

        assert!(
            account_addr == @my_addrx,
            error::invalid_state(EINVALID_TOKEN_OWNER)
        );

        let token_addr = account::create_resource_address(&@my_addrx, PROPERTY_TOKEN_SEED);

        let burn_cap = &borrow_global<PropertyTokenCapabilities>(token_addr).burn_capability;

        coin::burn_from(user_addr, amount, burn_cap);

        let event_data: &mut PropertyTokenEvents = borrow_global_mut<PropertyTokenEvents>(token_addr);

        event::emit_event<BurnAccountEvent>(
            &mut event_data.burn_account_event,
            BurnAccountEvent {
                account: account_addr,
                burn_account: user_addr,
                amount,
                timestamp: timestamp::now_seconds(),
            },
        )
    }
}
