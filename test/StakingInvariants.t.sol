// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/NFTStakingRewards.sol";
import "./NFTStakingRewards.t.sol";
import "./StakingHandler.sol";
import "../src/MockNFT.sol";

contract StakingInvariantsTest is Test {
    NFTStakingRewards public stakingContract;
    MockNFT public mockNFT;
    StakingHandler public handler;

    function setUp() public {
        mockNFT = new MockNFT();

        stakingContract = new NFTStakingRewards(
            address(mockNFT),
            "Staking Token",
            "STK"
        );
        handler = new StakingHandler(
            address(stakingContract),
            address(mockNFT)
        );

        targetContract(address(handler));
    }

    // 🛡️ THE GLOBAL SYSTEM INVARIANT TRUTH:
    // if the total number of locked or staked assets in the system is 0,
    // the sum of global reward generation or token supply velocity must also strictly be 0!

    function invariant_GlobalVelocityFreezeWhenPoolEmpty() public view {
        uint256 totalAssetsInEscrow = mockNFT.balanceOf(
            address(stakingContract)
        );

        if (totalAssetsInEscrow == 0) {
            assertEq(
                stakingContract.userRewardPerSecond(handler.actorPool(0)),
                0
            );
            assertEq(
                stakingContract.userRewardPerSecond(handler.actorPool(1)),
                0
            );
            assertEq(
                stakingContract.userRewardPerSecond(handler.actorPool(2)),
                0
            );
        }
    }
}
