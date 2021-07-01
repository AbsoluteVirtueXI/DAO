//SPDX-Licence-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC777/ERC777.sol";

/*
    NEVER DEPLOY THIS CONTRACT IN PRODUCTION
*/
contract Gouverno is ERC777 {
    constructor(address[] memory defaultOperators_) ERC777("Gouverno", "GVRN", defaultOperators_) {}

    // A free minting function just for testing purposes.
    function mint(uint256 amount) public {
        _mint(msg.sender, amount, "", "");
    }
}
