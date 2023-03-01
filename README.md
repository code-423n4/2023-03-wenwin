# Wenwin contest details
- Total Prize Pool: Sum of below awards
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

There is a certain scenario when lottery would run out of funds. This can happen in extreme scenarios when jackpot is won in consecutive draws, while the ticket sales were low. Probability of this happening is 0.3%. This issue will not be considered as valid.

# Overview

Wenwin is a decentralized gaming protocol that provides developers with the ability to create chance-based games on the blockchain. The first product is Lottery, and it is a subject of this audit contest. Very detailed documentation for the Lottery can be found [here](https://docs.wenwin.com/wenwin-lottery). All the contracts have extensive NatSpec comments. Most of the time NatSpec is located in interfaces, or base contracts.

# Scope

| Contract/Library | SLOC | Purpose | Libraries used |  
| ----------- | ----------- | ----------- | ----------- |
| [src/LotteryToken.sol](src/LotteryToken.sol) | 18 | Native token of Wenwin Lottery, used for staking and referral rewards | [`@openzeppelin/*`](https://openzeppelin.com/contracts/) |
| [src/LotteryMath.sol](src/LotteryMath.sol) | 81 | This library contains some basic math functions used by Wenwin Lottery | None |
| [src/PercentageMath.sol](src/PercentageMath.sol) | 11 | This library contains some basic percentage math functions and constants | None |
| [src/LotterySetup.sol](src/LotterySetup.sol) | 143 | Contains some basic params for the lottery | [`@openzeppelin/*`](https://openzeppelin.com/contracts/) |
| [src/Lottery.sol](src/Lottery.sol) | 220 | This contract is the main entry point for all Wenwin Lottery actions | [`@openzeppelin/*`](https://openzeppelin.com/contracts/) |
| [src/ReferralSystem.sol](src/ReferralSystem.sol) | 119 | This abstract contract implements Lottery referral system | [`@openzeppelin/*`](https://openzeppelin.com/contracts/) |
| [src/RNSourceBase.sol](src/RNSourceBase.sol) | 33 | Base abstract contract for random number source | None |
| [src/RNSourceController.sol](src/RNSourceController.sol) | 91 | This abstract contract implements logic for managing random number sources. | [`@openzeppelin/*`](https://openzeppelin.com/contracts/) |
| [src/VRFv2RNSource.sol](src/VRFv2RNSource.sol) | 30 | Chainlink VRFv2 random number source integration | [`@chainlink/*`](https://github.com/smartcontractkit/chainlink) |
| [src/Ticket.sol](src/Ticket.sol) | 16 | Represents lottery ticket as NFT, standard ERC721 | [`@openzeppelin/*`](https://openzeppelin.com/contracts/) |
| [src/TicketUtils.sol](src/TicketUtils.sol) | 68 | Library implementing utilities for ticket combination | None |
| [src/staking/Staking.sol](src/staking/Staking.sol) | 96 | Contract implementing native token staking to receive rewards coming from ticket sales | [`@openzeppelin/*`](https://openzeppelin.com/contracts/) |
| [src/staking/StakedTokenLock.sol](src/staking/StakedTokenLock.sol) | 36 | Implementation of staked token lock to be used for team tokens | [`@openzeppelin/*`](https://openzeppelin.com/contracts/) |

## Out of scope

All the contracts under test directory.

# Tests

To run the tests you need to:
1. [install Foundry](https://book.getfoundry.sh/getting-started/installation).
2. Clone the repo using `git clone --recurse-submodules`.
3. Run `forge test`

To generate coverage run `bash script/sh/generateCoverageReport.sh`. It will open HTML report in your default browser.

To get gas report run `forge test --gas-report`

More documentation on testing and lottery mechanics can be found in [Wenwin contracts readme](https://github.com/wenwincom/wenwin-contracts/blob/main/README.md).
