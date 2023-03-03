# Wenwin contest details

- Total Prize Pool: $36,500 USDC
  - HM awards: $25,500 USDC
  - QA report awards: $3,000 USDC
  - Gas report awards: $1,500 USDC
  - Judge + presort awards: $6,000 USDC
  - Scout awards: $500 USDC
- Join [C4 Discord](https://discord.gg/code4rena) to register
- Submit findings [using the C4 form](https://code4rena.com/contests/2023-03-wenwin-contest/submit)
- [Read our guidelines for more details](https://docs.code4rena.com/roles/wardens)
- Starts March 06, 2023 20:00 UTC
- Ends March 09, 2023 20:00 UTC

## Automated Findings / Publicly Known Issues

Automated findings output for the contest can be found [here](add link to report) within an hour of contest opening.

*Note for C4 wardens: Anything included in the automated findings output is considered a publicly known issue and is ineligible for awards.*

There is a certain scenario when the lottery would run out of funds. This can happen in extreme scenarios when the jackpot is won in consecutive draws, while the ticket sales were low. The probability of this happening is 0.3%. This issue will not be considered valid.

# Overview

Wenwin is a decentralized gaming protocol that provides developers with the ability to create chance-based games on the blockchain. The first product is Lottery, and it is the subject of this audit contest. All the contracts have extensive NatSpec comments and most of them are located in the interfaces or base contracts.

The protocol's main contracts are:

- [Lottery](src/Lottery.sol): The main entry point for all lottery actions, including buying tickets, claiming rewards, and executing draws. Issues [Ticket](src/Ticket.sol) ERC-721 NFTs to players. It inherits from [RNSourceController](src/RNSourceController.sol) that controls random number sources and prevents the lottery's owner from changing the source without it failing to deliver a random number for a while.
- [LotteryToken](src/LotteryToken.sol): The native token of Wenwin Lottery. It can be staked (stakers receive a portion of ticket sales) and referral rewards.
- [VRFv2RNSource](src/VRFv2RNSource.sol): The Chainlink VRFv2 random number source integration used for generating a winning ticket combination for a draw.
- [Staking](src/staking/Staking.sol): A contract implementing native token staking that receives rewards from ticket sales and distributes them to stakers.

For more detailed information about the protocol, please refer to the [Wenwin Lottery documentation](https://docs.wenwin.com/wenwin-lottery).

# Scope

## In scope


### Files in scope

|File|[SLOC](#nowhere "(nSLOC, SLOC, Lines)")|Description and [Coverage](#nowhere "(Lines hit / Total)")|Libraries|
|:-|:-:|:-|:-|
|_Contracts (6)_|
|[src/LotteryToken.sol](https://github.com/code-423n4/2023-03-wenwin/blob/main/src/LotteryToken.sol)|[18](#nowhere "(nSLOC:18, SLOC:18, Lines:28)")|The native token of Wenwin Lottery, used for staking and referral rewards, &nbsp;&nbsp;[100.00%](#nowhere "(Hit:3 / Total:3)")| [`@openzeppelin/*`](https://openzeppelin.com/contracts/)|
|[src/VRFv2RNSource.sol](https://github.com/code-423n4/2023-03-wenwin/blob/main/src/VRFv2RNSource.sol)|[30](#nowhere "(nSLOC:30, SLOC:30, Lines:39)")|A Chainlink VRFv2 random number source integration, &nbsp;&nbsp;[100.00%](#nowhere "(Hit:4 / Total:4)")| [`@chainlink/*`](https://github.com/smartcontractkit/chainlink)|
|[src/staking/StakedTokenLock.sol](https://github.com/code-423n4/2023-03-wenwin/blob/main/src/staking/StakedTokenLock.sol) [📤](#nowhere "Initiates ETH Value Transfer")|[36](#nowhere "(nSLOC:36, SLOC:36, Lines:57)")|An implementation of staked token lock to be used for team tokens, &nbsp;&nbsp;[100.00%](#nowhere "(Hit:10 / Total:10)")| [`@openzeppelin/*`](https://openzeppelin.com/contracts/)|
|[src/staking/Staking.sol](https://github.com/code-423n4/2023-03-wenwin/blob/main/src/staking/Staking.sol)|[96](#nowhere "(nSLOC:96, SLOC:96, Lines:125)")|A contract implementing native token staking, &nbsp;&nbsp;[100.00%](#nowhere "(Hit:36 / Total:36)")| [`@openzeppelin/*`](https://openzeppelin.com/contracts/)|
|[src/LotterySetup.sol](https://github.com/code-423n4/2023-03-wenwin/blob/main/src/LotterySetup.sol) [🌀](#nowhere "create/create2")|[143](#nowhere "(nSLOC:143, SLOC:143, Lines:177)")|A lottery parameters setup contract, &nbsp;&nbsp;[71.43%](#nowhere "(Hit:20 / Total:28)")| [`@openzeppelin/*`](https://openzeppelin.com/contracts/)|
|[src/Lottery.sol](https://github.com/code-423n4/2023-03-wenwin/blob/main/src/Lottery.sol) [🌀](#nowhere "create/create2")|[220](#nowhere "(nSLOC:200, SLOC:220, Lines:288)")|The main entry point for all Wenwin Lottery actions, &nbsp;&nbsp;[94.20%](#nowhere "(Hit:65 / Total:69)")| [`@openzeppelin/*`](https://openzeppelin.com/contracts/)|
|_Abstracts (4)_|
|[src/Ticket.sol](https://github.com/code-423n4/2023-03-wenwin/blob/main/src/Ticket.sol)|[16](#nowhere "(nSLOC:16, SLOC:16, Lines:28)")|A lottery ticket represented as NFT (ERC-721), &nbsp;&nbsp;[100.00%](#nowhere "(Hit:4 / Total:4)")| [`@openzeppelin/*`](https://openzeppelin.com/contracts/)|
|[src/RNSourceBase.sol](https://github.com/code-423n4/2023-03-wenwin/blob/main/src/RNSourceBase.sol)|[33](#nowhere "(nSLOC:33, SLOC:33, Lines:49)")|A base abstract contract for a random number source, &nbsp;&nbsp;[86.67%](#nowhere "(Hit:13 / Total:15)")||
|[src/RNSourceController.sol](https://github.com/code-423n4/2023-03-wenwin/blob/main/src/RNSourceController.sol) [♻️](#nowhere "TryCatch Blocks")|[91](#nowhere "(nSLOC:91, SLOC:91, Lines:121)")|An abstract contract that manages random number sources, &nbsp;&nbsp;[94.74%](#nowhere "(Hit:36 / Total:38)")| [`@openzeppelin/*`](https://openzeppelin.com/contracts/)|
|[src/ReferralSystem.sol](https://github.com/code-423n4/2023-03-wenwin/blob/main/src/ReferralSystem.sol)|[119](#nowhere "(nSLOC:107, SLOC:119, Lines:164)")|An abstract contract that implements Lottery referral system, &nbsp;&nbsp;[39.53%](#nowhere "(Hit:17 / Total:43)")| [`@openzeppelin/*`](https://openzeppelin.com/contracts/)|
|_Libraries (3)_|
|[src/PercentageMath.sol](https://github.com/code-423n4/2023-03-wenwin/blob/main/src/PercentageMath.sol)|[11](#nowhere "(nSLOC:11, SLOC:11, Lines:25)")|A library implementing percentage math functions and constants, &nbsp;&nbsp;[0.00%](#nowhere "(Hit:0 / Total:2)")||
|[src/TicketUtils.sol](https://github.com/code-423n4/2023-03-wenwin/blob/main/src/TicketUtils.sol) [Σ](#nowhere "Unchecked Blocks")|[68](#nowhere "(nSLOC:43, SLOC:68, Lines:102)")|A library implementing utilities for lottery ticket combinations, &nbsp;&nbsp;[100.00%](#nowhere "(Hit:24 / Total:24)")||
|[src/LotteryMath.sol](https://github.com/code-423n4/2023-03-wenwin/blob/main/src/LotteryMath.sol)|[81](#nowhere "(nSLOC:43, SLOC:81, Lines:131)")|A library implementing basic math functions used by Wenwin Lottery, &nbsp;&nbsp;[14.29%](#nowhere "(Hit:2 / Total:14)")||
|_Interfaces (11)_|
|[src/interfaces/IVRFv2RNSource.sol](https://github.com/code-423n4/2023-03-wenwin/blob/main/src/interfaces/IVRFv2RNSource.sol)|[7](#nowhere "(nSLOC:7, SLOC:7, Lines:18)")|-||
|[src/interfaces/ILotteryToken.sol](https://github.com/code-423n4/2023-03-wenwin/blob/main/src/interfaces/ILotteryToken.sol)|[8](#nowhere "(nSLOC:8, SLOC:8, Lines:23)")|-| [`@openzeppelin/*`](https://openzeppelin.com/contracts/)|
|[src/interfaces/ITicket.sol](https://github.com/code-423n4/2023-03-wenwin/blob/main/src/interfaces/ITicket.sol)|[11](#nowhere "(nSLOC:11, SLOC:11, Lines:30)")|-| [`@openzeppelin/*`](https://openzeppelin.com/contracts/)|
|[src/staking/interfaces/IStakedTokenLock.sol](https://github.com/code-423n4/2023-03-wenwin/blob/main/src/staking/interfaces/IStakedTokenLock.sol)|[14](#nowhere "(nSLOC:14, SLOC:14, Lines:41)")|-||
|[src/interfaces/IReferralSystemDynamic.sol](https://github.com/code-423n4/2023-03-wenwin/blob/main/src/interfaces/IReferralSystemDynamic.sol)|[18](#nowhere "(nSLOC:15, SLOC:18, Lines:36)")|-||
|[src/interfaces/IRNSource.sol](https://github.com/code-423n4/2023-03-wenwin/blob/main/src/interfaces/IRNSource.sol)|[22](#nowhere "(nSLOC:22, SLOC:22, Lines:55)")|-||
|[src/staking/interfaces/IStaking.sol](https://github.com/code-423n4/2023-03-wenwin/blob/main/src/staking/interfaces/IStaking.sol)|[23](#nowhere "(nSLOC:23, SLOC:23, Lines:72)")|-| [`@openzeppelin/*`](https://openzeppelin.com/contracts/)|
|[src/interfaces/IReferralSystem.sol](https://github.com/code-423n4/2023-03-wenwin/blob/main/src/interfaces/IReferralSystem.sol)|[28](#nowhere "(nSLOC:22, SLOC:28, Lines:74)")|-||
|[src/interfaces/IRNSourceController.sol](https://github.com/code-423n4/2023-03-wenwin/blob/main/src/interfaces/IRNSourceController.sol)|[29](#nowhere "(nSLOC:29, SLOC:29, Lines:91)")|-| [`@openzeppelin/*`](https://openzeppelin.com/contracts/)|
|[src/interfaces/ILottery.sol](https://github.com/code-423n4/2023-03-wenwin/blob/main/src/interfaces/ILottery.sol)|[54](#nowhere "(nSLOC:47, SLOC:54, Lines:169)")|-||
|[src/interfaces/ILotterySetup.sol](https://github.com/code-423n4/2023-03-wenwin/blob/main/src/interfaces/ILotterySetup.sol)|[59](#nowhere "(nSLOC:59, SLOC:59, Lines:163)")|-| [`@openzeppelin/*`](https://openzeppelin.com/contracts/)|
|Total (over 24 files):| [1235](#nowhere "(nSLOC:1124, SLOC:1235, Lines:2106)") |[80.69%](#nowhere "Hit:234 / Total:290")|


## External imports
* **@chainlink/contracts/src/v0.8/VRFV2WrapperConsumerBase.sol**
  * [src/VRFv2RNSource.sol](https://github.com/code-423n4/2023-03-wenwin/blob/main/src/VRFv2RNSource.sol)
* **@openzeppelin/contracts/access/Ownable2Step.sol**
  * [src/RNSourceController.sol](https://github.com/code-423n4/2023-03-wenwin/blob/main/src/RNSourceController.sol)
  * [src/interfaces/IRNSourceController.sol](https://github.com/code-423n4/2023-03-wenwin/blob/main/src/interfaces/IRNSourceController.sol)
  * [src/staking/StakedTokenLock.sol](https://github.com/code-423n4/2023-03-wenwin/blob/main/src/staking/StakedTokenLock.sol)
* **@openzeppelin/contracts/token/ERC20/ERC20.sol**
  * [src/LotteryToken.sol](https://github.com/code-423n4/2023-03-wenwin/blob/main/src/LotteryToken.sol)
  * [src/staking/Staking.sol](https://github.com/code-423n4/2023-03-wenwin/blob/main/src/staking/Staking.sol)
* **@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol**
  * [src/LotterySetup.sol](https://github.com/code-423n4/2023-03-wenwin/blob/main/src/LotterySetup.sol)
* **@openzeppelin/contracts/token/ERC20/IERC20.sol**
  * [src/interfaces/ILotterySetup.sol](https://github.com/code-423n4/2023-03-wenwin/blob/main/src/interfaces/ILotterySetup.sol)
  * [src/interfaces/ILotteryToken.sol](https://github.com/code-423n4/2023-03-wenwin/blob/main/src/interfaces/ILotteryToken.sol)
  * [src/staking/interfaces/IStaking.sol](https://github.com/code-423n4/2023-03-wenwin/blob/main/src/staking/interfaces/IStaking.sol)
* **@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol**
  * [src/Lottery.sol](https://github.com/code-423n4/2023-03-wenwin/blob/main/src/Lottery.sol)
  * [src/staking/Staking.sol](https://github.com/code-423n4/2023-03-wenwin/blob/main/src/staking/Staking.sol)
* **@openzeppelin/contracts/token/ERC721/ERC721.sol**
  * [src/Ticket.sol](https://github.com/code-423n4/2023-03-wenwin/blob/main/src/Ticket.sol)
* **@openzeppelin/contracts/token/ERC721/IERC721.sol**
  * [src/interfaces/ITicket.sol](https://github.com/code-423n4/2023-03-wenwin/blob/main/src/interfaces/ITicket.sol)
* **@openzeppelin/contracts/utils/math/Math.sol**
  * [src/Lottery.sol](https://github.com/code-423n4/2023-03-wenwin/blob/main/src/Lottery.sol)
  * [src/LotterySetup.sol](https://github.com/code-423n4/2023-03-wenwin/blob/main/src/LotterySetup.sol)
  * [src/ReferralSystem.sol](https://github.com/code-423n4/2023-03-wenwin/blob/main/src/ReferralSystem.sol)



## Out of scope

All the contracts under the `test` and `script` directories.

## Scoping Details 
```
- If you have a public code repo, please share it here:  https://github.com/wenwincom/wenwin-contracts
- How many contracts are in scope?:   13
- Total SLoC for these contracts?:  962
- How many external imports are there?: Open Zeppelin, ChainLink
- How many separate interfaces and struct definitions are there for the contracts within scope?:  11
- Does most of your code generally use composition or inheritance?: We use inheritance for Lottery contract to divide responsibility of the contract.
- How many external calls?: 3
- What is the overall line coverage percentage provided by your tests?:  100
- Is there a need to understand a separate part of the codebase / get context in order to audit this part of the protocol?: false  
- Please describe required context:   n/a
- Does it use an oracle?:  true (ChainLink VRFv2 randomness oracle)
- Does the token conform to the ERC20 standard?:  yes
- Are there any novel or unique curve logic or mathematical models?: None
- Does it use a timelock function?:  Yes (Native token staking implements time lock)
- Is it an NFT?: Yes (Lottery Ticket is an NFT)
- Does it have an AMM?:   No
- Is it a fork of a popular project?:   false
- Does it use rollups?:   false
- Is it multi-chain?:  false
- Does it use a side-chain?: false 
```

# Tests

More documentation on testing and lottery mechanics can be found in [Wenwin contracts README](https://github.com/wenwincom/wenwin-contracts/blob/main/README.md).

## Quickstart command

`rm -Rf 2023-03-wenwin || true && git clone https://github.com/code-423n4/2023-03-wenwin.git -j8 --recurse-submodules && cd 2023-03-wenwin && foundryup && forge test --gas-report`

## Forge tests

To run the tests you need to:

1. [Install Foundry](https://book.getfoundry.sh/getting-started/installation).
2. Clone the repo using `git clone --recurse-submodules`.
3. Run `forge test`.

## Coverage

To generate coverage, run:

```bash
bash script/sh/generateCoverageReport.sh
```

It will open the HTML report in your browser.

## Gas report

To get the gas report, run:

```bash
forge test --gas-report
```

## Slither

To run Slither, run:

```bash
slither .
```

## Echidna

To run Echidna tests in assertion mode, run:

```bash
echidna-test . --contract LotteryEchidna --config echidna.assertion.config.yaml
```

To run Echidna tests in property mode, run:

```bash
echidna-test . --contract LotteryEchidnaProperty --config echidna.property.config.yaml
```
