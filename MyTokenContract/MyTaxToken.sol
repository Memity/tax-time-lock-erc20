// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/* 
 *  - Standard ERC20 (OpenZeppelin)
 *  - Owner can set a tax up to 2%
 *  - Tax goes to a treasury address
 *  - Basic time lock for changing the tax (48-hour or variable)
 *
 * PLEASE AUDIT BEFORE DEPLOYING ANY REAL VALUE!
 * Adjust code or disclaimers as necessary for your project.
 */

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NAME is ERC20, Ownable {

    // ======= CONSTANTS / LIMITS =======
    uint256 public constant MAX_SUPPLY = 1_000_000_000 * 10**18; // 1B tokens, 18 decimals
    uint256 public constant MAX_TAX_PERCENT = 2; // Max 2%
    uint256 public constant TIME_LOCK_DURATION = 48 hours; // 2-day time lock for tax changes

    // ======= STATE VARIABLES =======
    // The address that receives the tax
    address public treasury;

    // Current tax in basis points (e.g., 100 = 1%)
    // We store tax in basis points for finer control. 200 = 2%, 100 = 1%, etc.
    uint256 public taxBasisPoints;

    // Time lock state to mitigate sudden tax changes
    uint256 public pendingTaxBasisPoints;
    uint256 public taxChangeUnlockTime; // when we can apply the pending tax

    // Mapping to exclude certain addresses from tax if needed (e.g. liquidity pool)
    mapping (address => bool) public isTaxExempt;

    // ======= EVENTS =======
    event TaxQueued(uint256 newTaxBP, uint256 unlockTime);
    event TaxApplied(uint256 newTaxBP);
    event TreasuryAddressChanged(address newTreasury);
    event ExemptStatusChanged(address indexed account, bool isExempt);

    // ======= CONSTRUCTOR =======
    constructor(address _treasury) ERC20("NAME", "NAME") {
        require(_treasury != address(0), "Treasury cannot be zero address");

        treasury = _treasury;
        // Initially, no tax
        taxBasisPoints = 0;

        // Mint total supply to msg.sender
        _mint(msg.sender, MAX_SUPPLY);
    }

    // ======= OVERRIDE ERC20 TRANSFER LOGIC =======
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override {
        require(sender != address(0), "ERC20: transfer from zero");
        require(recipient != address(0), "ERC20: transfer to zero");

        if (isTaxExempt[sender] || isTaxExempt[recipient] || taxBasisPoints == 0) {
            // No tax if either address is exempt or tax is 0
            super._transfer(sender, recipient, amount);
        } else {
            // Calculate tax
            uint256 taxAmount = (amount * taxBasisPoints) / 10000; 
            uint256 netAmount = amount - taxAmount;

            // Transfer tax to treasury
            if (taxAmount > 0) {
                super._transfer(sender, treasury, taxAmount);
            }
            // Transfer the remainder to recipient
            super._transfer(sender, recipient, netAmount);
        }
    }

    // ======= TAX MANAGEMENT FUNCTIONS =======

    /**
     * @dev Initiates a time-locked change to the tax basis points.
     *  e.g. newTaxBP=100 -> 1%, 200 -> 2%, 0 -> no tax.
     */
    function queueTaxChange(uint256 _newTaxBP) external onlyOwner {
        require(_newTaxBP <= MAX_TAX_PERCENT * 100, "Exceeds max tax of 2%");
        // Set pending changes
        pendingTaxBasisPoints = _newTaxBP;
        taxChangeUnlockTime = block.timestamp + TIME_LOCK_DURATION;

        emit TaxQueued(_newTaxBP, taxChangeUnlockTime);
    }

    /**
     * @dev After time lock passes, owner can apply the pending tax.
     */
    function applyTaxChange() external onlyOwner {
        require(block.timestamp >= taxChangeUnlockTime, "Time lock not expired");
        // Apply the pending tax
        taxBasisPoints = pendingTaxBasisPoints;

        // Reset the pending values
        pendingTaxBasisPoints = 0;
        taxChangeUnlockTime = 0;

        emit TaxApplied(taxBasisPoints);
    }

    /**
     * @dev Allows owner to instantly set tax to zero in emergency (optional).
     * You can remove this function if you want strict time lock for all changes.
     */
    function emergencySetTaxToZero() external onlyOwner {
        taxBasisPoints = 0;
        // Optionally reset queue
        pendingTaxBasisPoints = 0;
        taxChangeUnlockTime = 0;
        emit TaxApplied(0);
    }

    // ======= TREASURY & EXEMPTIONS =======
    function setTreasury(address _treasury) external onlyOwner {
        require(_treasury != address(0), "Zero address not allowed");
        treasury = _treasury;
        emit TreasuryAddressChanged(_treasury);
    }

    /**
     * @dev Exclude or include an address from tax (like DEX or liquidity pool)
     */
    function setTaxExempt(address account, bool exempt) external onlyOwner {
        isTaxExempt[account] = exempt;
        emit ExemptStatusChanged(account, exempt);
    }

    // ======= OPTIONAL SAFETY MEASURES =======

    /**
     * @dev Renounce ownership if you want to finalize settings.
     * BUT you'll lose ability to change tax or treasury, so be cautious.
     */
    function renounceOwnership() public override onlyOwner {
        // If you want a final unstoppable token, call this. 
        // No more tax changes or treasury updates can happen afterward.
        super.renounceOwnership();
    }

}
