// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

// contract MockNFT is ERC721 {
//     uint256 public currentTokenId;

//     constructor() ERC721("Mock Bored Ape", "mBAYC") {}

//     function mint() external returns (uint256) {
//         currentTokenId++;
//         _safeMint(msg.sender, currentTokenId);
//         return currentTokenId;
//     }
// }

contract MockNFT is ERC721 {
    uint256 public currentTokenId;

    constructor() ERC721("Mock Bored Ape", "mBAYC") {}

    function mint(address to) external returns (uint256) {
        currentTokenId++;
        _safeMint(to, currentTokenId);
        return currentTokenId;
    }

    function mintToCustomId(address to, uint256 _tokenId) external {
        _safeMint(to, _tokenId);
    }
}
