# Cryptographically Audited Multi-Tier NFT Staking & Yield Accumulator Protocol

An enterprise-grade, audit-ready **Decentralized NFT Staking & Rewards Protocol** engineered using **Solidity v0.8.13** and the **Foundry** native testing framework. This protocol features multi-tier dynamic yield speed structures based on ERC-721 metadata rarity, secured completely against initial state vulnerabilities, reentrancy vectors, and reward dilution exploits.

## 🚀 Protocol Design & Core Mechanics
- **Dynamic Multi-Tier Staking:** Computes active yields without gas-heavy arrays by shifting individual user velocities instantly (`userRewardPerSecond`) using strict asset metadata configuration tiers.
- **Atomic State Operations:** Implements rigid Checks-Effects-Interactions (CEI) blueprints. Internal ledger records (`rewards[msg.sender]`) are completely wiped to zero **prior** to executing the underlying OpenZeppelin token mint loops, neutralizing reentrancy execution trajectories.
- **Empty-Pool Velocity Guard:** Features automated state tracking that immediately freezes global reward velocity variables whenever the total assets locked in escrow collapse to zero, blocking unallocated yield leaks.

---

## 🛡️ Advanced Security Auditing Matrix (Stateful Invariants & Transitions)

To satisfy production-grade deployment requirements, this protocol is backed by a hybrid testing matrix combining targeted boundary transition scripts and full **Stateful Invariant Fuzzing**.

### 1. The Empty-Pool Boundary Transition Test (`test_Auditor_YieldLeak_Transition`)
Following rigorous security design specs, this targeted transition test isolates a high-risk DeFi exploit vector across zero-liquidity boundaries:
- **Scenario:** `Alice deposits (accrues rewards) -> Alice withdraws entire stake (Pool drops to 0 locked assets) -> Empty Interval (10 days time-warp) -> Bob deposits.`
- **Assertion Specification:** Mathematically validates that Alice retains only her precise pre-exit earned balance without drift, and guarantees that Bob starts from a clean zero-base without inheriting dangling tokens or unallocated yields generated during the empty interval gap.

### 2. The Stateful Fuzzing Handler Strategy (`StakingHandler.sol`)
To prevent the fuzzer from causing false-positive reverts on random data parameters, this ecosystem utilizes a dedicated Proxy Simulation Handler. The handler uses the Modulo (`%`) operator to filter random fuzz variables into valid operational index points (`activeTokenIds`), forcing the fuzzing engine to exclusively fire deep cross-function paths (`stakeRandomNFT`, `withdrawRandomNFT`) across dynamic test identities.

### 3. The Global Invariant Constant (`StakingInvariants.t.sol`)
The main invariant suite monitors a permanent system absolute truth over thousands of chained, randomized executions:
- **Global Invariant:** If `totalAssetsInEscrow == 0`, then `userRewardPerSecond` for all dynamic system actors must strictly resolve to `0`. If this check ever breaks, a serious reward velocity drift or calculation bug is active inside the protocol state.

---

## 🚨 Vulnerability Discovery: Initial Timestamp Reward Dilution Patched

### 🔴 The Vulnerability (Root Cause)
In the initial architecture of the internal helper `_updateReward(address _user)`, the balance delta computation relied directly on mapping initializations. When a user interacted with the protocol for the first time, `lastStakedTime[_user]` defaulted to `0`. 

When the user staked their first asset, `lastStakedTime` updated to `block.timestamp`. However, if that user returned to deposit a subsequent NFT days later, the contract fired `_updateReward()` again. Because the legacy framework failed to isolate the initial setup boundary condition, the math calculated a massive time delta dating back to the network's genesis block, allowing users to mint millions of free reward tokens out of thin air.

### 🟢 The Resolution (The Patch)
The exploit matrix was permanently neutralized by wrapping the tracking allocation loop inside an active balance constraint check:
```solidity
if (userStakedCount[_user] > 0) {
    rewards[_user] += (block.timestamp - lastStakedTime[_user]) * userRewardPerSecond[_user];
}
```
This ensures that if the active account vault is empty, the logic skips the historical lookup buffer and updates only the baseline tracking timeline.

---

## 💻 Compilation & Testing Commands

### 1. Build Local Bindings
```bash
forge install openzeppelin/openzeppelin-contracts --no-commit
forge compile
```

### 2. Execute Happy Paths & Targeted Transition Tests
```bash
forge test --match-contract NFTStakingRewardsTest -vvv
```

### 3. Run High-Velocity Stateful Invariant Fuzzing
```bash
forge clean && forge test --match-contract StakingInvariantsTest -vvv
```

---

## 📄 License
This protocol infrastructure is released as open-source software under the **MIT License**.
