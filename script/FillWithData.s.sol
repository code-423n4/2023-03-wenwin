// SPDX-License-Identifier: UNLICENSED
// slither-disable-next-line solc-version
pragma solidity 0.8.19;

import "forge-std/Script.sol";
import "src/interfaces/ILottery.sol";
import "test/RNSource.sol";
import "test/TestToken.sol";

contract FillWithDataScript is Script {
    uint256 public deployerPrivateKey;

    TestToken public token;
    ILottery public lottery;
    RNSource public randomNumberSource;

    // solhint-disable-next-line no-empty-blocks
    function setUp() public { }

    function run() public {
        deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        lottery = ILottery(vm.envAddress("LOTTERY_ADDRESS"));
        token = TestToken(vm.envAddress("REWARD_TOKEN_ADDRESS"));
        randomNumberSource = RNSource(vm.envAddress("RNSOURCE_ADDRESS"));

        uint256 option = vm.envUint("FILL_WITH_DATA_OPTION");
        if (option == 1) {
            initializePot();
        } else if (option == 2) {
            finalizePotRaise();
        } else if (option == 3) {
            buyTickets();
        } else if (option == 4) {
            executeDraw();
        }
    }

    function initializePot() internal {
        vm.startBroadcast(deployerPrivateKey);
        token.mint(100 ether);
        token.approve(address(lottery), type(uint256).max);
        token.transfer(address(lottery), 100 ether);
    }

    function finalizePotRaise() internal {
        vm.broadcast(deployerPrivateKey);
        lottery.finalizeInitialPotRaise();
    }

    function buyTickets() internal {
        uint128 currentDraw = lottery.currentDraw();

        uint128[] memory drawIds = new uint128[](5);
        drawIds[0] = currentDraw;
        drawIds[1] = currentDraw;
        drawIds[2] = currentDraw;
        drawIds[3] = currentDraw;
        drawIds[4] = currentDraw;
        uint120[] memory tickets = new uint120[](5);
        tickets[0] = 0x7F;
        tickets[1] = 0x111F;
        tickets[2] = 0x1010F10;
        tickets[3] = 0x101011111;
        tickets[4] = 0x02031302;

        vm.startBroadcast(deployerPrivateKey);
        token.mint(100 ether);
        token.approve(address(lottery), type(uint256).max);
        lottery.buyTickets(drawIds, tickets, address(666), address(0));
        vm.stopBroadcast();
    }

    function executeDraw() internal {
        uint256 currentDraw = lottery.currentDraw();

        vm.startBroadcast(deployerPrivateKey);
        lottery.executeDraw();
        uint256 randomNumber = 0x0101011111;
        randomNumberSource.fulfillRandomNumber(randomNumber);
        vm.stopBroadcast();

        console.log("Executed draw", currentDraw, "with random number", randomNumber);
    }
}
