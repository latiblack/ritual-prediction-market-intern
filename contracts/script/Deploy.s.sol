// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {MarketFetcher} from "../src/MarketFetcher.sol";
import {MarketAnalyzer} from "../src/MarketAnalyzer.sol";
import {ScheduledMarketFetcher} from "../src/ScheduledMarketFetcher.sol";

/**
 * @title DeployScript
 * @notice Deploys contracts to Ritual Chain.
 *
 * Usage:
 *   # Deploy MarketFetcher (basic on-chain fetch)
 *   forge script script/Deploy.s.sol:DeployFetcher --rpc-url $RITUAL_RPC_URL --broadcast -vvvv
 *
 *   # Deploy MarketAnalyzer (fetch + LLM analysis)
 *   forge script script/Deploy.s.sol:DeployAnalyzer --rpc-url $RITUAL_RPC_URL --broadcast -vvvv
 *
 *   # Deploy ScheduledMarketFetcher (daily auto-fetch via Scheduler)
 *   forge script script/Deploy.s.sol:DeployScheduled --rpc-url $RITUAL_RPC_URL --broadcast -vvvv
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

contract DeployScheduled is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address executor = vm.envAddress("HTTP_EXECUTOR");

        console.log("Deploying ScheduledMarketFetcher...");
        console.log("Executor:", executor);

        vm.startBroadcast(deployerPrivateKey);
        ScheduledMarketFetcher fetcher = new ScheduledMarketFetcher(executor);
        vm.stopBroadcast();

        console.log("ScheduledMarketFetcher deployed at:", address(fetcher));
        console.log("");
        console.log("Next steps:");
        console.log("  1. Deposit RITUAL into RitualWallet:");
        console.log("     cast send", address(fetcher), "\"deposit()\" --value 0.5ether --rpc-url $RITUAL_RPC_URL --private-key $PRIVATE_KEY");
        console.log("  2. Start daily scheduler:");
        console.log("     cast send", address(fetcher), "\"startScheduler()\" --rpc-url $RITUAL_RPC_URL --private-key $PRIVATE_KEY");
        console.log("  3. Check scheduler state:");
        console.log("     cast call", address(fetcher), "\"getSchedulerState()(uint8)\" --rpc-url $RITUAL_RPC_URL");
        console.log("  4. Read latest result:");
        console.log("     cast call", address(fetcher), "\"getLatest()(uint256,uint16,bytes,string)\" --rpc-url $RITUAL_RPC_URL");
        console.log("  5. Manual fetch (for testing):");
        console.log("     cast send", address(fetcher), "\"fetchNow()\" --rpc-url $RITUAL_RPC_URL --private-key $PRIVATE_KEY");
        console.log("  6. Read round 1:");
        console.log("     cast call", address(fetcher), "\"getRound(uint256)((uint256,uint16,bytes,string))\" 1 --rpc-url $RITUAL_RPC_URL");
    }
}
