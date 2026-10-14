// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {
    IERC721Receiver
} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract NFTStakingRewards is ERC20, IERC721Receiver, Ownable {
    IERC721 public immutable nftToken;

    mapping(uint256 => uint256) public nftTier;
    mapping(uint256 => address) public nftOwner;
    mapping(address => uint256) public rewards;
    mapping(address => uint256) public lastStakedTime;
    mapping(address => uint256) public userRewardPerSecond;
    mapping(address => uint256) public userStakedCount;

    event Staked(address indexed user, uint256 tokenId);
    event Withdrawn(address indexed user, uint256 tokenId);
    event ClaimReward(address indexed user, uint256 amount);

    constructor(
        address _nftToken,
        string memory _tokenName,
        string memory _tokenSymbol
    ) ERC20(_tokenName, _tokenSymbol) Ownable(msg.sender) {
        nftToken = IERC721(_nftToken);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
    
    function _updateReward(address _user) internal {
        if (userStakedCount[_user] > 0) {
            rewards[_user] +=
                (block.timestamp - lastStakedTime[_user]) *
                userRewardPerSecond[_user];
        }

        lastStakedTime[_user] = block.timestamp;
    }

    function stake(uint256 _tokenId) external {
        require(nftToken.ownerOf(_tokenId) == msg.sender, "Not the owner");
        require(nftTier[_tokenId] > 0, "NFT tier not assigned");

        _updateReward(msg.sender);
        userRewardPerSecond[msg.sender] += nftTier[_tokenId];
        userStakedCount[msg.sender]++;

        nftOwner[_tokenId] = msg.sender;
        nftToken.safeTransferFrom(msg.sender, address(this), _tokenId);

        emit Staked(msg.sender, _tokenId);
    }

    function withdraw(uint256 _tokenId) external {
        require(nftOwner[_tokenId] == msg.sender, "Not the owner");

        _updateReward(msg.sender);

        userRewardPerSecond[msg.sender] -= nftTier[_tokenId];
        userStakedCount[msg.sender]--;

        nftOwner[_tokenId] = address(0);
        nftToken.safeTransferFrom(address(this), msg.sender, _tokenId);

        emit Withdrawn(msg.sender, _tokenId);
    }

    function claimReward() external {
        _updateReward(msg.sender);

        uint256 rewardAmount = rewards[msg.sender];
        require(rewardAmount > 0, "Not reward available");

        rewards[msg.sender] = 0;
        _mint(msg.sender, rewardAmount);

        emit ClaimReward(msg.sender, rewardAmount);
    }

    function setNftTier(uint256 _tokenId, uint256 _tier) external onlyOwner {
        require(_tier > 0 && _tier <= 3, "Invalid tier level");
        require(
            nftOwner[_tokenId] == address(0),
            "Cannot change tier while staked"
        );
        nftTier[_tokenId] = _tier;
    }
}
