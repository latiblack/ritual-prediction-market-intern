// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {MarketFetcher} from "../src/MarketFetcher.sol";
import {MarketAnalyzer} from "../src/MarketAnalyzer.sol";

/**
 * @title DeployScript
 * @notice Deploys MarketFetcher and optionally MarketAnalyzer to Ritual Chain.
 *
 * Usage:
 *   # Deploy MarketFetcher only
 *   forge script script/Deploy.s.sol:DeployFetcher --rpc-url $RITUAL_RPC_URL --broadcast -vvvv
 *
 *   # Deploy MarketAnalyzer (needs HTTP executor + LLM executor addresses)
 *   forge script script/Deploy.s.sol:DeployAnalyzer --rpc-url $RITUAL_RPC_URL --broadcast -vvvv
 */
contract DeployFetcher is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address executor = vm.envAddress("HTTP_EXECUTOR");

        console.log("Deploying MarketFetcher...");
        console.log("Executor:", executor);

        vm.startBroadcast(deployerPrivateKey);
        MarketFetcher fetcher = new MarketFetcher(executor);
        vm.stopBroadcast();

        console.log("MarketFetcher deployed at:", address(fetcher));
        console.log("");
        console.log("Next steps:");
        console.log("  1. Deposit RITUAL into RitualWallet:");
        console.log("     cast send", address(fetcher), "\"deposit()\" --value 0.1ether --rpc-url $RITUAL_RPC_URL --private-key $PRIVATE_KEY");
        console.log("  2. Fetch markets:");
        console.log("     cast send", address(fetcher), "\"fetchMarkets(uint256)\" 10 --rpc-url $RITUAL_RPC_URL --private-key $PRIVATE_KEY");
        console.log("  3. Read result:");
        console.log("     cast call", address(fetcher), "\"getLastResult()(uint16,string,bytes)\" --rpc-url $RITUAL_RPC_URL");
    }
}

contract DeployAnalyzer is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address httpExecutor = vm.envAddress("HTTP_EXECUTOR");
        address llmExecutor  = vm.envAddress("LLM_EXECUTOR");

        console.log("Deploying MarketAnalyzer...");
        console.log("HTTP Executor:", httpExecutor);
        console.log("LLM Executor:", llmExecutor);

        vm.startBroadcast(deployerPrivateKey);
        MarketAnalyzer analyzer = new MarketAnalyzer(httpExecutor, llmExecutor);
        vm.stopBroadcast();

        console.log("MarketAnalyzer deployed at:", address(analyzer));
        console.log("");
        console.log("Next steps:");
        console.log("  1. Deposit RITUAL:");
        console.log("     cast send", address(analyzer), "\"deposit()\" --value 0.2ether --rpc-url $RITUAL_RPC_URL --private-key $PRIVATE_KEY");
        console.log("  2. Fetch markets:");
        console.log("     cast send", address(analyzer), "\"fetchMarkets(uint256)\" 10 --rpc-url $RITUAL_RPC_URL --private-key $PRIVATE_KEY");
        console.log("  3. Read market data:");
        console.log("     cast call", address(analyzer), "\"getLastMarketData()(uint16,string,bytes)\" --rpc-url $RITUAL_RPC_URL");
    }
}
