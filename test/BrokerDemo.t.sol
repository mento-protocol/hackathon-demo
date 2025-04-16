// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {BrokerDemo} from "../src/BrokerDemo.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IMentoRouter} from "../src/interfaces/IMentoRouter.sol";

contract BrokerDemoTest is Test {
    BrokerDemo public brokerDemo;
    address public constant MENTO_ROUTER =
        0xBE729350F8CdFC19DB6866e8579841188eE57f67;
    address public constant BI_POOL_MANAGER =
        0x22d9db95E6Ae61c104A7B6F6C78D7993B94ec901;
    address public constant CUSD = 0x765DE816845861e75A25fCA122bb6898B8B1282a;
    address public constant USDC = 0xcebA9300f2b948710d2653dD7B07f33A8B32118C;
    address public constant CEUR = 0xD8763CBa276a3738E6DE85b4b3bF5FDed6D6cA73;

    // Test user address with some CUSD balance
    address public TEST_USER = makeAddr("TEST_USER");

    function setUp() public {
        // Create a fork of Celo mainnet
        vm.createSelectFork(vm.envString("CELO_MAINNET_RPC_URL"));

        // Deploy the broker contract
        brokerDemo = new BrokerDemo();

        // Mint CUSD to the test user
        deal(CUSD, TEST_USER, 1000 * 10 ** 18);
    }

    function testConstants() public view {
        assertEq(
            brokerDemo.MENTO_ROUTER(),
            MENTO_ROUTER,
            "MentoRouter address should match"
        );
        assertEq(
            brokerDemo.BI_POOL_MANAGER(),
            BI_POOL_MANAGER,
            "BiPoolManager address should match"
        );
        assertEq(brokerDemo.CUSD(), CUSD, "CUSD address should match");
        assertEq(brokerDemo.USDC(), USDC, "USDC address should match");
        assertEq(brokerDemo.CEUR(), CEUR, "CEUR address should match");
    }

    function testSwapCUSDForCEUR() public {
        // Get initial balances
        uint256 initialCUSDBalance = IERC20Metadata(CUSD).balanceOf(TEST_USER);
        uint256 initialCEURBalance = IERC20Metadata(CEUR).balanceOf(TEST_USER);

        // Approve the router to spend CUSD
        vm.startPrank(TEST_USER);
        IERC20Metadata(CUSD).approve(address(brokerDemo), type(uint256).max);

        // Swap 1 CUSD
        uint256 amountIn = 1e18;

        // Get expected output amount from router
        IMentoRouter.Step[] memory path = new IMentoRouter.Step[](2);
        bytes32 CUSD_USDC_ExchangeId = keccak256(
            abi.encodePacked(
                IERC20Metadata(CUSD).symbol(),
                IERC20Metadata(USDC).symbol(),
                "ConstantSum"
            )
        );
        bytes32 USDC_CEUR_ExchangeId = keccak256(
            abi.encodePacked(
                IERC20Metadata(CEUR).symbol(),
                IERC20Metadata(USDC).symbol(),
                "ConstantSum"
            )
        );

        path[0] = IMentoRouter.Step({
            exchangeProvider: BI_POOL_MANAGER,
            exchangeId: CUSD_USDC_ExchangeId,
            assetIn: CUSD,
            assetOut: USDC
        });
        path[1] = IMentoRouter.Step({
            exchangeProvider: BI_POOL_MANAGER,
            exchangeId: USDC_CEUR_ExchangeId,
            assetIn: USDC,
            assetOut: CEUR
        });

        uint256 expectedOut = IMentoRouter(MENTO_ROUTER).getAmountOut(
            amountIn,
            path
        );

        // Perform the swap
        brokerDemo.swapCUSDForCEUR(amountIn, 0);

        // Check final balances
        uint256 finalCUSDBalance = IERC20Metadata(CUSD).balanceOf(TEST_USER);
        uint256 finalCEURBalance = IERC20Metadata(CEUR).balanceOf(TEST_USER);

        // Verify balances changed as expected
        assertEq(
            finalCUSDBalance,
            initialCUSDBalance - amountIn,
            "CUSD balance should decrease by amountIn"
        );
        assertApproxEqRel(
            finalCEURBalance - initialCEURBalance,
            expectedOut,
            1e16, // 1% tolerance
            "CEUR balance should increase by expected amount"
        );
    }
}
