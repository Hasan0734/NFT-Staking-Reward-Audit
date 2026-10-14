// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import "../src/NFTStakingRewards.sol";
import "../src/MockNFT.sol";
import "forge-std/Test.sol";
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

    // // ==========================================
    // // 🛡️ SECTION 2: ADVANCED AUDITOR TRANSITION TESTS
    // // ==========================================

    // /**
    //  * @dev SPECIFICATION & INTENDED REWARD POLICY
    //  * ---------------------------------------------------------------------------------------
    //  * 1. Dynamic Multi-Tier Yeild Accumulation: User yields are mathmatically tracked using
    //  *    the `userRewardPerSecond` metric, derived from the NFT rarity tier configuration.
    //  * 2. Zero-Staker Poll Velocity Protection: When the total pool locks collapse to exactly
    //  *    0 assets, the aggregrate reward velocity must immdediately freeze. No new global rewards
    //  *    should ever accrue during an empty interval window.
    //  * 3. Isolation of Historical Entitlements: Exting users must cleanly lock down only their
    //  *    pre-exit earned rewards. Future incoming stakers (e.g., Bob) must start from a zero
    //  *    base index and must NEVER inherit dangling or unallocated yields from the empty interval gap.
    //  * ---------------------------------------------------------------------------------------
    //  */

    function test_Auditor_YieldLeak_Transition() public {
        stakingContract.setNftTier(1, 2);

        // --- Alice start stake ---
        vm.deal(alice, 10 ether);
        vm.startPrank(alice);
        mockNFT.mint(alice);
        uint256 aliceTokenId = mockNFT.currentTokenId();

        mockNFT.approve(address(stakingContract), aliceTokenId);
        stakingContract.stake(aliceTokenId);
        vm.stopPrank();

        vm.warp(block.timestamp + 5 days);

        vm.startPrank(alice);
        uint256 aliceEarnedBeforeExit = stakingContract.rewards(alice) +
            ((block.timestamp - stakingContract.lastStakedTime(alice)) *
                stakingContract.userRewardPerSecond(alice));
        stakingContract.withdraw(aliceTokenId);
        vm.stopPrank();

        // --- Empty interval: 0 pool 10 later ---
        vm.warp(block.timestamp + 10 days);

        // --- Bob start staking on 0 pool ---

        stakingContract.setNftTier(2, 2);

        vm.deal(bob, 10 ether);
        vm.startPrank(bob);
        mockNFT.mint(bob);
        uint256 bobTokenId = mockNFT.currentTokenId();

        mockNFT.approve(address(stakingContract), bobTokenId);
        stakingContract.stake(bobTokenId);
        vm.stopPrank();

        assertEq(
            stakingContract.rewards(alice),
            aliceEarnedBeforeExit,
            "Alice leaked rewards post-exit!"
        );
        assertEq(
            stakingContract.rewards(bob),
            0,
            "Bob inherited tokens from empty interval!"
        );
    }

    // ==========================================
    // 🚨 SECTION 3: DEPLOYMENT GENESIS TIMESTAMP EXPLOIT FIX PROOF
    // ==========================================

    function test_Fix_InitialTimestampProtection() public {
        vm.deal(hacker, 10 ether);

        // hacker stake token (id: 1)
        vm.startPrank(hacker);
        mockNFT.mint(hacker);
        uint256 id1 = mockNFT.currentTokenId();
        vm.stopPrank();

        stakingContract.setNftTier(id1, 2);

        vm.startPrank(hacker);
        mockNFT.approve(address(stakingContract), id1);
        stakingContract.stake(id1);
        vm.stopPrank();

        // 5 days later
        vm.warp(block.timestamp + 5 days);

        // hacker 2 stake token (id: 2)
        vm.startPrank(hacker);
        mockNFT.mint(hacker);
        uint256 id2 = mockNFT.currentTokenId();
        vm.stopPrank();
        stakingContract.setNftTier(id2, 2);

        vm.startPrank(hacker);
        mockNFT.approve(address(stakingContract), id2);

        // action: 2 second time stake backdated trap block check
        stakingContract.stake(id2);
        vm.stopPrank();

        uint256 expectedReward = 5 days * 2;
        assertEq(
            stakingContract.rewards(hacker),
            expectedReward,
            "Timestamp math diluted!"
        );
    }
}
