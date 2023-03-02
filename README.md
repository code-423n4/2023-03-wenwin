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

| Contract/Library                                                   | SLOC | Purpose                                                                       | Libraries used                                                  |
| ------------------------------------------------------------------ | ---- | ----------------------------------------------------------------------------- | --------------------------------------------------------------- |
| [src/LotteryToken.sol](src/LotteryToken.sol)                       | 18   | The native token of Wenwin Lottery, used for staking and referral rewards     | [`@openzeppelin/*`](https://openzeppelin.com/contracts/)        |
| [src/LotteryMath.sol](src/LotteryMath.sol)                         | 81   | A library implementing basic math functions used by Wenwin Lottery            | None                                                            |
| [src/PercentageMath.sol](src/PercentageMath.sol)                   | 11   | A library implementing percentage math functions and constants                | None                                                            |
| [src/LotterySetup.sol](src/LotterySetup.sol)                       | 143  | A lottery parameters setup contract                                           | [`@openzeppelin/*`](https://openzeppelin.com/contracts/)        |
| [src/Lottery.sol](src/Lottery.sol)                                 | 220  | The main entry point for all Wenwin Lottery actions                           | [`@openzeppelin/*`](https://openzeppelin.com/contracts/)        |
| [src/ReferralSystem.sol](src/ReferralSystem.sol)                   | 119  | An abstract contract that implements Lottery referral system                  | [`@openzeppelin/*`](https://openzeppelin.com/contracts/)        |
| [src/RNSourceBase.sol](src/RNSourceBase.sol)                       | 33   | A base abstract contract for a random number source                           | None                                                            |
| [src/RNSourceController.sol](src/RNSourceController.sol)           | 91   | An abstract contract that manages random number sources                       | [`@openzeppelin/*`](https://openzeppelin.com/contracts/)        |
| [src/VRFv2RNSource.sol](src/VRFv2RNSource.sol)                     | 30   | A Chainlink VRFv2 random number source integration                            | [`@chainlink/*`](https://github.com/smartcontractkit/chainlink) |
| [src/Ticket.sol](src/Ticket.sol)                                   | 16   | A lottery ticket represented as NFT (ERC-721)                                 | [`@openzeppelin/*`](https://openzeppelin.com/contracts/)        |
| [src/TicketUtils.sol](src/TicketUtils.sol)                         | 68   | A library implementing utilities for lottery ticket combinations              | None                                                            |
| [src/staking/Staking.sol](src/staking/Staking.sol)                 | 96   | A contract implementing native token staking                                  | [`@openzeppelin/*`](https://openzeppelin.com/contracts/)        |
| [src/staking/StakedTokenLock.sol](src/staking/StakedTokenLock.sol) | 36   | An implementation of staked token lock to be used for team tokens             | [`@openzeppelin/*`](https://openzeppelin.com/contracts/)        |


## Out of scope

All the contracts under the `test` and `script` directories.

# Tests

More documentation on testing and lottery mechanics can be found in [Wenwin contracts README](https://github.com/wenwincom/wenwin-contracts/blob/main/README.md).

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
