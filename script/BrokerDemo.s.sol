// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {BrokerDemo} from "../src/BrokerDemo.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract BrokerDemoScript is Script {
    // Address of the already deployed BrokerDemo contract
    address public constant BROKER_DEMO =
        0xf2e257e82233C6b0a52FaF6658c9304711cEe55E; // TODO: Replace with actual deployed address

    function setUp() public {}

    function run() public {
        // Get the private key from the environment
        uint256 userPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(userPrivateKey);

        // Get the broker contract instance
        BrokerDemo demo = BrokerDemo(BROKER_DEMO);
        console.log("Using BrokerDemo at:", BROKER_DEMO);

        // Get token addresses
        address cUSD = demo.CUSD();
        address cEUR = demo.CEUR();

        // Get the user's address
        address user = vm.addr(userPrivateKey);
        console.log("User address:", user);

        // Get initial balances
        uint256 initialCUSDBalance = ERC20(cUSD).balanceOf(user);
        uint256 initialCEURBalance = ERC20(cEUR).balanceOf(user);
        console.log("Initial cUSD balance:", initialCUSDBalance);
        console.log("Initial cEUR balance:", initialCEURBalance);

        // Approve the broker to spend cUSD
        ERC20(cUSD).approve(BROKER_DEMO, type(uint256).max);
        console.log("Approved broker to spend cUSD");

        // Perform a swap of 0.01 cUSD
        uint256 amountIn = 1e16; // 0.01 cUSD
        console.log("Swapping", amountIn, "cUSD for cEUR...");
        demo.swapCUSDForCEUR(amountIn, 0);

        // Get final balances
        uint256 finalCUSDBalance = ERC20(cUSD).balanceOf(user);
        uint256 finalCEURBalance = ERC20(cEUR).balanceOf(user);
        console.log("Final cUSD balance:", finalCUSDBalance);
        console.log("Final cEUR balance:", finalCEURBalance);
        console.log("cUSD spent:", initialCUSDBalance - finalCUSDBalance);
        console.log("cEUR received:", finalCEURBalance - initialCEURBalance);

        vm.stopBroadcast();
    }
}
