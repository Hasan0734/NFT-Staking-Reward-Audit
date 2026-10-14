// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/NFTStakingRewards.sol";
import "../src/MockNFT.sol";
import "./NFTStakingRewards.t.sol";

contract StakingHandler is Test {
    NFTStakingRewards public stakingContract;
    MockNFT public mockNFT;

    uint256[] public activeTokenIds;
    address[] public actorPool;

    constructor(address _stakingContract, address _mockNFT) {
        stakingContract = NFTStakingRewards(_stakingContract);
        mockNFT = MockNFT(_mockNFT);

        // 3 random fuzz users

        actorPool.push(makeAddr("Actro_Alice"));
        actorPool.push(makeAddr("Actro_Bob"));
        actorPool.push(makeAddr("Actro_Hacker"));
    }

    // 1. Randomized Staking Fuzz Function

    function stakeRandomNFT(uint256 _actorSeed, uint256 _tierSeed) external {
        if (actorPool.length == 0) return;
        address user = actorPool[_actorSeed % actorPool.length];

        // Tier level 1 to 3 bounded
        uint256 tier = bound(_tierSeed, 1, 3);

        vm.startPrank(user);
        mockNFT.mint(user);
        uint256 tokenId = mockNFT.currentTokenId();
        activeTokenIds.push(tokenId);
        vm.stopPrank();

        stakingContract.setNftTier(tokenId, tier);

        vm.startPrank(user);
        mockNFT.approve(address(stakingContract), tokenId);
        stakingContract.stake(tokenId);
        vm.stopPrank();
    }

    // 2. Randomized Withdraw Fuzz Function

    function withdrawRandomnNFT(uint256 _tokenSeed) external {
        if (activeTokenIds.length == 0) return;

        uint256 tokenId = activeTokenIds[_tokenSeed % activeTokenIds.length];
        address currentStaker = stakingContract.nftOwner(tokenId);

        // if token is not available then skip

        vm.startPrank(currentStaker);
        stakingContract.withdraw(tokenId);
        vm.stopPrank();
    }
}
