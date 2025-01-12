# Tax-Time-Lock Token (Example)

This is a demonstration ERC20 token contract (Solidity ^0.8.17) with:
- Up to 2% tax going to a treasury address
- A time lock (48 hours) for changing the tax
- Ownership logic to update treasury or exempt addresses

## Disclaimer
- This code is for demonstration. Please audit thoroughly before use in production.
- Originally designed for an EVM-compatible network like Base chain.

## Features
- `queueTaxChange(newTaxBasisPoints)` sets a pending tax, unlocked after 48 hours.
- `applyTaxChange()` applies that new tax once the time lock expires.
- `emergencySetTaxToZero()` can set tax to 0 instantly, if needed.

## Setup
1. Clone this repo.
2. Compile via Hardhat or Remix (importing OpenZeppelin dependencies).
3. Test or deploy on any EVM chain.

(Adjust as necessary)
