module my_addrx::marketplace {
    use aptos_framework::timestamp;
    use aptos_framework::account;
    use aptos_framework::account::SignerCapability;
    use aptos_framework::guid;
    use std::signer;
    use std::string;
    use aptos_std::event::{Self, EventHandle};
    use aptos_std::table::{Self, Table};
    use std::error;
    use my_addrx::property_coin;
    
    //Error codes
    
    ///owner is invalid
    const EINVALID_OWNER: u64 = 0;
    ///Property already exists 
    const EPROPERTY_ALREADY_EXISTS: u64 = 1;
    ///Invalid property name 
    const EINVALID_PROPERTY_NAME: u64 = 2;
    ///Entity already exists
    const EALREADY_EXISTS: u64 = 4;
    ///Seller cannot be the buyer
    const ESELLER_CANNOT_BE_BUYER: u64 = 5;
    ///Insufficient funds
    const EINSUFFICIENT_FUNDS: u64 = 6;

    
    //constants
    const PROPERTY_SEED: vector<u8> = b"MARKETPLACE:RESOURCE_ACCOUNT";
    const PLATFORM_FEE: u64 = 10;
    
    //Structs
    struct MarketCapability has key {
        capability: SignerCapability
    }
    
    //
    struct PropertyDetail has store, drop {
        property_name: string::String,
        amount: u64,
        timestamp: u64,
        listing_id: u64,
        seller_address: address
    }

    struct UserPropertyDetail has store {
        property_name: string::String,
        amount: u64,
        owner_address: address
    }

    struct UserPropertyList has key {
        user_property_list: Table<string::String, UserPropertyDetail>
    }

    struct ListingEvent has drop, store {
        property_name: string::String,
        amount: u64,
        timestamp: u64,
        listing_id: u64,
        seller_address: address
    }

    struct DelistingEvent has drop, store {
        property_name: string::String,
        amount: u64,
        timestamp: u64,
        listing_id: u64,
        seller_address: address
    }

    struct PriceChangeEvent has drop, store {
        property_name: string::String,
        amount: u64,
        timestamp: u64,
        listing_id: u64,
        seller_address: address
    }

    struct BuyPropertyEvent has drop, store {
        property_name: string::String,
        amount: u64,
        timestamp: u64,
        buyer_address: address
    }

    struct PropertyListing has key {
        listed_properties: Table<string::String, PropertyDetail>,
        listing_event: EventHandle<ListingEvent>,
        delisting_event: EventHandle<DelistingEvent>,
        price_change_event: EventHandle<PriceChangeEvent>,
        buy_property_event: EventHandle<BuyPropertyEvent>
    }
    
    /**
     * @notice Initializes the marketplace module
     * @dev This function is called during the contract deployment to set up the marketplace.
     * @param sender The address of the deploying signer.
     */
     
    public entry fun initialize(sender: &signer) {
        let sender_address = signer::address_of(sender);

        assert!(sender_address == @my_addrx, error::permission_denied(EINVALID_OWNER));

        let (market_signer, market_capability) = account::create_resource_account(sender, PROPERTY_SEED);

        if (!exists<MarketCapability>(sender_address)) {
            move_to(&market_signer, MarketCapability { capability: market_capability });
        };

        if (!exists<PropertyListing>(sender_address)) {
            move_to(
                &market_signer,
                PropertyListing {
                    listed_properties: table::new<string::String, PropertyDetail>(),
                    listing_event: account::new_event_handle<ListingEvent>(&market_signer),
                    delisting_event: account::new_event_handle<DelistingEvent>(&market_signer),
                    price_change_event: account::new_event_handle<PriceChangeEvent>(&market_signer),
                    buy_property_event: account::new_event_handle<BuyPropertyEvent>(&market_signer),
                },
            );
        }
    }

    /**
     * @notice Lists a property in the marketplace
     * @dev This function allows property owners to list their properties in the marketplace.
     * @param seller The signer listing the property.
     * @param amount The amount of the property to be listed.
     * @param property_name The name of the property to be listed.
     */

    public entry fun list_property(seller: &signer, amount: u64, property_name: string::String) acquires MarketCapability, PropertyListing, UserPropertyList {
        let seller_address: address = signer::address_of(seller);
        let (market_signer, market_address): (signer, address) = return_market_signer_address();
        let listed_properties_data: &mut PropertyListing = borrow_global_mut<PropertyListing>(market_address);
        let temp_list_property: &mut Table<string::String, PropertyDetail> = &mut listed_properties_data.listed_properties;
        let guid: guid::GUID = account::create_guid(&market_signer);
        let listing_id: u64 = guid::creation_num(&guid);

        assert!(
            table::contains(temp_list_property, property_name),
            error::already_exists(EPROPERTY_ALREADY_EXISTS)
        );
        assert!(property_coin::balance(seller_address) > PLATFORM_FEE , error::aborted(EINSUFFICIENT_FUNDS));

        table::add(
            temp_list_property,
            property_name,
            PropertyDetail {
                property_name,
                amount,
                timestamp: timestamp::now_seconds(),
                listing_id,
                seller_address,
            },
        );

        if (!exists<UserPropertyList>(seller_address)) {
            move_to(
                seller,
                UserPropertyList {
                    user_property_list: table::new<string::String, UserPropertyDetail>()
                }
            );

            let temp_property_details = &mut borrow_global_mut<UserPropertyList>(seller_address).user_property_list;
            table::add(temp_property_details ,property_name ,UserPropertyDetail{
                property_name,
                amount,
                owner_address: seller_address
            })

        } else {
            
            let temp_property_details = &mut borrow_global_mut<UserPropertyList>(seller_address).user_property_list;
            assert!(!table::contains(temp_property_details ,property_name ),error::already_exists(EALREADY_EXISTS));

             table::add(temp_property_details ,property_name ,UserPropertyDetail{
                    property_name,
                    amount,
                    owner_address: seller_address
                })
        };

        property_coin::transfer_property_token(seller ,market_address  , PLATFORM_FEE );
       

        event::emit_event<ListingEvent>(
            &mut listed_properties_data.listing_event,
            ListingEvent {
                property_name,
                amount,
                timestamp: timestamp::now_seconds(),
                listing_id,
                seller_address,
            },
        )
    }
    /**
     * @notice Delists a property from the marketplace
     * @dev This function allows property owners to delist their properties from the marketplace.
     * @param seller The signer delisting the property.
     * @param property_name The name of the property to be delisted.
     */
    public entry fun delist_property(seller: &signer, property_name: string::String) acquires PropertyListing, MarketCapability {
        let seller_address: address = signer::address_of(seller);
        let (_, market_address): (signer, address) = return_market_signer_address();
        let listed_properties_data: &mut PropertyListing = borrow_global_mut<PropertyListing>(market_address);
        let temp_list_property: &mut Table<string::String, PropertyDetail> = &mut listed_properties_data.listed_properties;
        let temp_property_details: &PropertyDetail = table::borrow(temp_list_property, property_name);

        assert!(exists<UserPropertyList>(seller_address), error::permission_denied(EINVALID_OWNER));
        assert!(table::contains(temp_list_property, property_name), error::not_found(EINVALID_PROPERTY_NAME));
        assert!(
            &temp_property_details.seller_address == &seller_address,
            error::permission_denied(EINVALID_OWNER)
        );

        let PropertyDetail {
            property_name,
            amount,
            timestamp,
            listing_id,
            seller_address,
        } = table::remove(temp_list_property, property_name);

        event::emit_event<DelistingEvent>(
            &mut listed_properties_data.delisting_event,
            DelistingEvent {
                property_name,
                amount,
                timestamp,
                listing_id,
                seller_address,
            },
        )
    }

     /**
     * @notice Buys a property from the marketplace
     * @dev This function allows users to buy properties from the marketplace.
     * @param buyer The signer buying the property.
     * @param property_name The name of the property to be bought.
     */

    public entry fun buy_property(buyer: &signer, property_name: string::String) acquires PropertyListing, MarketCapability , UserPropertyList {
        let buyer_address = signer::address_of(buyer);
        let (_, market_address) = return_market_signer_address();

        let listed_properties_data: &mut PropertyListing = borrow_global_mut<PropertyListing>(market_address);
        let temp_property_details: &mut Table<string::String, PropertyDetail> = &mut listed_properties_data.listed_properties;
        let temp_property_details_user  = &mut borrow_global_mut<UserPropertyList>(buyer_address).user_property_list;
        assert!(
            table::contains(temp_property_details, property_name),
            error::not_found(EINVALID_PROPERTY_NAME)
        );

        assert!(
            table::borrow(temp_property_details_user, property_name).owner_address == buyer_address,
            error::permission_denied(ESELLER_CANNOT_BE_BUYER)
        );

        let PropertyDetail {
            property_name: _,
            amount,
            timestamp: _,
            listing_id: _,
            seller_address,
        } = table::remove(temp_property_details, property_name);

        assert!(property_coin::balance(buyer_address) > PLATFORM_FEE + amount , error::aborted(EINSUFFICIENT_FUNDS));

        // considering the price of the token as 10 rs
        let temp_price = 10 * amount;
        property_coin::transfer_property_token(buyer, seller_address, temp_price);

        property_coin::transfer_property_token(buyer ,market_address  , PLATFORM_FEE );
       

        let  UserPropertyDetail {
              property_name,
              amount,
              owner_address:_
              } = table::remove(temp_property_details_user ,property_name );


        if (!exists<UserPropertyList>(buyer_address)) {
            move_to(
                buyer,
                UserPropertyList {
                    user_property_list : table::new<string::String , UserPropertyDetail>()
                }
            );

            table::add(temp_property_details_user ,property_name ,UserPropertyDetail{
                property_name,
                amount,
                owner_address: buyer_address
            })
        } else {
            table::add(temp_property_details_user ,property_name ,UserPropertyDetail{
                property_name,
                amount,
                owner_address: buyer_address
            })
        };   
         

        event::emit_event<BuyPropertyEvent>(
            &mut listed_properties_data.buy_property_event,
            BuyPropertyEvent {
                property_name,
                amount,
                timestamp: timestamp::now_seconds(),
                buyer_address,
            },
        )
    }
    /**
    * @title Return Market Signer Address Function
    * @dev Returns the signer and address associated with the market capability.
    * @return market_signer The signer associated with the market capability.
    * @return market_address The address associated with the market capability.
    * @param acquires MarketCapability
    */
    fun return_market_signer_address(): (signer, address) acquires MarketCapability {
        let market_capability: &SignerCapability = &borrow_global<MarketCapability>(@my_addrx).capability;
        let market_signer: signer = account::create_signer_with_capability(market_capability);
        let market_address: address = signer::address_of(&market_signer);
        (market_signer, market_address)
    }
}
