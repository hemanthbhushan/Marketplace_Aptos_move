# Marketplace Module

The `marketplace` module facilitates the listing, delisting, and purchasing of properties in a marketplace. Each property is represented by a `PropertyDetail` struct, and the module keeps track of listed properties using a `Table`. Additionally, it manages user-specific property information in a `UserPropertyList`.

## Table of Contents
- [Error Codes](#error-codes)
- [Structs](#structs)
- [Events](#events)
- [Public Functions](#public-functions)
  - [initialize](#initialize)
  - [list_property](#list_property)
  - [delist_property](#delist_property)
  - [buy_property](#buy_property)
  - [return_market_signer_address](#return_market_signer_address)
- [Commands](#commands)
  - [Initialize Project](#initialize-project)
  - [Initialize Account](#initialize-account)
  - [Initialize Additional Account](#initialize-additional-account)
  - [Publish/Deploy Contract](#publishdeploy-contract)
  - [Compile](#compile)
  - [Test](#test)
  - [Run Function](#run-function)
  - [View Function](#view-function)

## Error Codes
1. `ERROR_INVALID_OWNER`: The sender is not the expected owner.
2. `ERROR_PROPERTY_ALREADY_EXISTS`: The property with the given name already exists.
3. `ERROR_INVALID_PROPERTY_NAME`: The specified property does not exist.
4. `ERROR_ALREADY_EXISTS`: The resource already exists.
5. `ERROR_SELLER_CANNOT_BE_BUYER`: The seller cannot be the buyer.
6. `ERROR_INSUFFICIENT_FUNDS`: Insufficient funds to perform the operation.
7. `ERROR_INSUFFICIENT_PLATFORM_FEE`: Insufficient platform fee.

## Structs

### MarketCapability
- **capability**: SignerCapability

### PropertyDetail
- **property_name**: string::String
- **amount**: u64
- **timestamp**: u64
- **listing_id**: u64
- **seller_address**: address

### UserPropertyDetail
- **property_name**: string::String
- **amount**: u64
- **owner_address**: address

### UserPropertyList
- **user_property_list**: Table<string::String, UserPropertyDetail>

### ListingEvent
- **property_name**: string::String
- **amount**: u64
- **timestamp**: u64
- **listing_id**: u64
- **seller_address**: address

### DelistingEvent
- **property_name**: string::String
- **amount**: u64
- **timestamp**: u64
- **listing_id**: u64
- **seller_address**: address

### PriceChangeEvent
- **property_name**: string::String
- **amount**: u64
- **timestamp**: u64
- **listing_id**: u64
- **seller_address**: address

### BuyPropertyEvent
- **property_name**: string::String
- **amount**: u64
- **timestamp**: u64
- **buyer_address**: address

### PropertyListing
- **listed_properties**: Table<string::String, PropertyDetail>
- **listing_event**: EventHandle<ListingEvent>
- **delisting_event**: EventHandle<DelistingEvent>
- **price_change_event**: EventHandle<PriceChangeEvent>
- **buy_property_event**: EventHandle<BuyPropertyEvent>

## Events

- **ListingEvent**
- **DelistingEvent**
- **PriceChangeEvent**
- **BuyPropertyEvent**

## Public Functions

### initialize
```move
public entry fun initialize(sender: &signer)
```
- Initializes the marketplace module, creating a resource account for the sender and setting up data structures.

### list_property
```move
public entry fun list_property(seller: &signer, amount: u64, property_name: string::String) acquires MarketCapability, PropertyListing, UserPropertyList
```
- Lists a property for sale in the marketplace.

### delist_property
```move
public entry fun delist_property(seller: &signer, property_name: string::String) acquires PropertyListing, MarketCapability
```
- Removes a listed property from the marketplace.

### buy_property
```move
public entry fun buy_property(buyer: &signer, property_name: string::String) acquires PropertyListing, MarketCapability, UserPropertyList
```
- Allows a buyer to purchase a listed property.

### return_market_signer_address
```move
fun return_market_signer_address(): (signer, address) acquires MarketCapability
```
- Returns the signer and address of the marketplace module.

## Commands

### Initialize Project
```bash
aptos move init --name projectname
```
- Initializes a Move project named `projectname`.

### Initialize Account
```bash
aptos init
```
- Creates a default account for use in the project.

### Initialize Additional Account
```bash
aptos init --profile accountname
```
- Creates an additional account with the specified profile `accountname`.

### Publish/Deploy Contract
```bash
aptos move publish
```
- Publishes or deploys the Move contract to the blockchain.
### Publish/Deploy Contract with Named Address and Private Key
```bash
aptos move publish --named-addresses my_addrx=0x4b68f19d3afd9c53cb7e6caa89929cc432e0e1c8124945e6504d096b3d796068 --private-key 0x6cf8b57c96c505045da044a14a55570456ae9cd832fbd3c16b27a77030d7622e --url https://fullnode.devnet.aptoslabs.com --assume-yes
```

### Compile
```bash
aptos move compile
```
- Compiles the Move contract.

### Test
```bash
aptos move test 
```
- Runs tests for the Move contract.
- Test cases for the above module have not been written yet.

### Run Function
```bash
aptos move run --function-id --args [pass the arguments with the arguments type]
```
- Executes a function from the CLI with the specified function ID and arguments.

Example:
```bash
aptos move run --function-id module_address::property_coin::initialize_property_token --args string:"PropertyToken" string:"PT" u8:18 bool:true
```

### View Function
```bash
aptos move view --function-id [function name]
```
- Views the result of a view function with the specified function name.

Example:
```bash
aptos move view --function-id module_address::property_coin::decimals
```

Feel free to adapt this README to your specific needs. It provides a comprehensive guide to commands and functions associated with the Move marketplace module.
