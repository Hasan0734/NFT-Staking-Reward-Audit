// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import {NFTStakingRewards} from "../src/NFTStakingRewards.sol";
import {MockNFT} from "../src/MockNFT.sol";

import {Test} from "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract NFTStakingRewardsTest is Test {
    NFTStakingRewards public stakingContract;
    MockNFT public mockNFT;

    // test user wallets
    address public alice = makeAddr("Alice");
    address public bob = makeAddr("Bob");
    address public hacker = makeAddr("Hacker");

    function setUp() public {
        mockNFT = new MockNFT();

        // main staking contract initiate
        stakingContract = new NFTStakingRewards(
            address(mockNFT),
            "Staking Rewards Token",
            "SRT"
        );
    }

    receive() external payable {}

    // ==========================================
    // 🟢 SECTION 1: CORE HAPPY CASES (STANDARD FUNCTIONALITIES)
    // ==========================================

    function test_Stake_Success() public {
        stakingContract.setNftTier(1, 2);

        vm.startPrank(alice);
        mockNFT.mint(alice);
        uint256 tokenId = mockNFT.currentTokenId();
        mockNFT.approve(address(stakingContract), tokenId);
        stakingContract.stake(tokenId);
        vm.stopPrank();
        assertEq(stakingContract.nftOwner(tokenId), alice);
        assertEq(stakingContract.userRewardPerSecond(alice), 2);
    }

    function test_Withdraw_Success() public {
        stakingContract.setNftTier(1, 2);

        vm.startPrank(alice);
        mockNFT.mint(alice);
        uint256 tokenId = mockNFT.currentTokenId();

        mockNFT.approve(address(stakingContract), tokenId);
        stakingContract.stake(tokenId);

        // 5 days later withdraw
        vm.warp(block.timestamp + 5 days);
        stakingContract.withdraw(tokenId);
        vm.stopPrank();

        assertEq(stakingContract.nftOwner(tokenId), address(0));
        assertEq(mockNFT.ownerOf(tokenId), alice);
    }

    function test_ClaimReward_Success() public {
        stakingContract.setNftTier(1, 2);

        vm.startPrank(alice);
        mockNFT.mint(alice);
        uint256 tokenId = mockNFT.currentTokenId();
        mockNFT.approve(address(stakingContract), tokenId);
        stakingContract.stake(tokenId);

        // 10 seconds fast forward
        vm.warp(block.timestamp + 10);
        stakingContract.withdraw(tokenId);
        stakingContract.claimReward();
        vm.stopPrank();

        // 10 seconds * 2 speed = 20 reward  expected mint token
        assertEq(stakingContract.balanceOf(alice), 20);
    }

}
