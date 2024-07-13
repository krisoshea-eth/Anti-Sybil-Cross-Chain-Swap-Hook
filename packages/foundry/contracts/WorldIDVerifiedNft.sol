// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract WorldIDVerifiedNFT is ERC721, Ownable {
    uint256 private _tokenIdCounter;

    constructor() ERC721("WorldIDVerified", "WIV") Ownable(msg.sender) {}

    function mint(address to) public onlyOwner {
        uint256 tokenId = _tokenIdCounter;
        _tokenIdCounter++;
        _safeMint(to, tokenId);
    }

    function _update(address to, uint256 tokenId, address auth) internal virtual override returns (address) {
        address from = _ownerOf(tokenId);
        
        // Only allow minting and burning, prevent transfers
        require(from == address(0) || to == address(0), "This NFT is non-transferrable");

        return super._update(to, tokenId, auth);
    }

    // Disable approval functions
    function approve(address to, uint256 tokenId) public virtual override {
        revert("Approvals are not allowed for this NFT");
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        revert("Approvals are not allowed for this NFT");
    }
}