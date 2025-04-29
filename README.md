### CryptoCustody Smart Contract

## Overview

CryptoCustody is a decentralized smart contract built on the Stacks blockchain that enables time-locked crypto asset transfers upon owner inactivity. This contract serves as a "dead man's switch" for cryptocurrency assets, allowing users to designate beneficiaries who can claim their assets after a specified period of inactivity.

## Features

- **Asset Protection**: Secure your crypto assets with a time-locked mechanism
- **Beneficiary Management**: Designate up to 5 beneficiaries who can receive your assets
- **Trustee System**: Appoint trusted individuals who can confirm disbursement requests
- **Customizable Dormancy Period**: Set your own inactivity threshold
- **Multi-signature Confirmation**: Require multiple trustees to approve disbursements
- **Regular Check-ins**: Simple mechanism to reset the inactivity timer


## How It Works

1. **Account Creation**: Users create an account specifying beneficiaries, a dormancy period, and required confirmations
2. **Asset Deposit**: Users can deposit assets (represented as principals) into their account
3. **Regular Check-ins**: Users must check in periodically to reset their activity timestamp
4. **Trustee Registration**: Users can register trusted individuals as trustees
5. **Disbursement Process**: If a user becomes inactive beyond their specified dormancy period:

1. Anyone can initiate a disbursement request
2. Registered trustees must confirm the request
3. Once enough confirmations are collected, the assets can be disbursed to beneficiaries





## Contract Functions

### Account Management

- `create-account`: Create a new custody account
- `deposit-asset`: Add an asset to your account
- `check-in`: Reset your activity timestamp
- `register-trustee`: Add a trusted individual who can confirm disbursements


### Disbursement Process

- `initiate-disbursement`: Start the process to disburse assets from an inactive account
- `confirm-disbursement`: As a trustee, confirm a disbursement request
- `execute-disbursement`: Execute the disbursement after sufficient confirmations


### Read-only Functions

- `get-account-info`: View information about an account
- `get-request-status`: Check the status of a disbursement request


## Deployment

To deploy this contract on the Stacks blockchain:

1. Install the [Clarinet](https://github.com/hirosystems/clarinet) development environment
2. Create a new project: `clarinet new crypto-custody`
3. Replace the default contract with this CryptoCustody contract
4. Test locally: `clarinet console`
5. Deploy to testnet/mainnet using Clarinet's deployment tools


## Usage Examples

### Creating an Account

```plaintext
;; Create an account with 2 beneficiaries, 52560 blocks dormancy (~1 year), and requiring 2 confirmations
(contract-call? .crypto-custody create-account 
  (list 'ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5 'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG) 
  u52560 
  u2)
```

### Depositing Assets

```plaintext
;; Deposit an asset (represented by a principal)
(contract-call? .crypto-custody deposit-asset 'SP456FG7H8J9K0LMNOPQRSTUVWXYZ12345.my-token)
```

### Checking In

```plaintext
;; Reset your activity timestamp
(contract-call? .crypto-custody check-in)
```

### Registering Trustees

```plaintext
;; Register a trustee
(contract-call? .crypto-custody register-trustee 'ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5)
```

### Initiating Disbursement

```plaintext
;; Initiate disbursement for an inactive account
(contract-call? .crypto-custody initiate-disbursement 'ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5)
```

## Security Considerations

- The contract includes validation for all input parameters
- Multiple trustees are required for disbursement to prevent unauthorized access
- The dormancy period is customizable based on user needs
- Self-registration as a trustee is prevented
- Asset limits are enforced to prevent resource exhaustion


## Limitations

- The contract currently supports a maximum of 100 assets per account
- A maximum of 5 beneficiaries can be designated
- The contract does not handle the actual transfer of tokens - it only manages the authorization logic
- Actual token transfers would need to be implemented
