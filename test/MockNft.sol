// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";

contract OurNFT is ERC721("OurNFT", "ONFT") {
    function tokenURI() public view virtual returns (string memory) {
        return "";
    }

    function mint(address recipient, uint256 tokenId) public payable {
        _mint(recipient, tokenId);
    }
}
