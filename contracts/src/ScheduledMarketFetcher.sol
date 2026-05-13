// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title ScheduledMarketFetcher
 * @notice Fetches Polymarket market data on-chain daily via Ritual's Scheduler.
 *
 * The Scheduler precompile (0x56e7) calls back this contract every ~24 hours.
 * Each call triggers the HTTP precompile (0x0801) to fetch live Polymarket data.
 * Results are stored with block timestamps for on-chain history.
 *
 * ⛓️ Flow:
 *   1. Deploy → set executor
 *   2. Deposit RITUAL into RitualWallet (covers both fetch gas + scheduler gas)
 *   3. Call startScheduler() → registers with Ritual's Scheduler
 *   4. Scheduler calls scheduledFetch() daily → HTTP precompile → market data stored
 *
 * Ritual Chain (~350ms block time):
 *   - daily frequency ≈ 250,000 blocks
 *   - numCalls = 365 (auto-stop after 1 year)
 */
contract ScheduledMarketFetcher {
    // ── Precompiles & System Contracts ──
    address constant HTTP_PRECOMPILE  = address(0x0801);
    address constant RITUAL_WALLET    = 0x532F0dF0896F353d8C3DD8cc134e8129DA2a3948;
    address constant SCHEDULER        = 0x56e776BAE2DD60664b69Bd5F865F1180ffB7D58B;

    // ── Constants ──
    uint32  constant DAILY_FREQUENCY  = 250_000; // blocks (~24h at 350ms)
    uint32  constant MAX_CALLS        = 365;     // auto-stop after 1 year
    uint32  constant CALL_GAS         = 500_000; // gas per scheduled execution
    uint256 constant TTL              = 500;     // max TTL blocks

    // ── Events ──
    event MarketDataFetched(uint256 indexed round, uint16 statusCode, string errorMessage, bytes body);
    event SchedulerStarted(uint256 callId);
    event SchedulerCancelled(uint256 callId);
    event ExecutorUpdated(address oldExecutor, address newExecutor);

    // ── State ──
    address public executor;
    uint256 public schedulerCallId;
    uint256 public fetchCount;

    // Round-based storage
    struct MarketSnapshot {
        uint256 timestamp;
        uint16  statusCode;
        bytes   body;
        string  errorMessage;
    }
    mapping(uint256 => MarketSnapshot) public rounds;
    uint256 public latestRound;

    // ── Constructor ──
    constructor(address _executor) {
        require(_executor != address(0), "executor required");
        executor = _executor;
    }

    // ── Admin ──
    function setExecutor(address _executor) external {
        require(_executor != address(0), "executor required");
        emit ExecutorUpdated(executor, _executor);
        executor = _executor;
    }

    // ── RitualWallet Deposit ──
    function deposit() external payable {
        (bool ok, ) = RITUAL_WALLET.call{value: msg.value}(
            abi.encodeWithSignature("deposit(uint256)", 5000)
        );
        require(ok, "deposit failed");
    }

    // ── Scheduler ──

    /// @notice Start daily market fetching. Requires RITUAL in RitualWallet.
    function startScheduler() external {
        require(executor != address(0), "no executor set");
        require(schedulerCallId == 0, "already scheduled");

        // Encode the callback: the Scheduler calls scheduledFetch(uint256)
        // The first uint256 param (bytes 4-35) is overwritten with executionIndex
        bytes memory data = abi.encodeCall(this.scheduledFetch, (uint256(0)));

        // Schedule: every DAILY_FREQUENCY blocks, MAX_CALLS times
        uint256 callId = IScheduler(SCHEDULER).schedule(
            data,
            CALL_GAS,
            MAX_CALLS,
            DAILY_FREQUENCY
        );

        schedulerCallId = callId;
        emit SchedulerStarted(callId);
    }

    /// @notice Called by the Scheduler. executionIndex is injected by the Scheduler.
    function scheduledFetch(uint256 /* executionIndex */) external {
        require(msg.sender == SCHEDULER, "only scheduler");
        require(executor != address(0), "no executor set");

        _fetchAndStore();
    }

    /// @notice Cancel the scheduler.
    function cancelScheduler() external {
        require(schedulerCallId != 0, "not scheduled");
        IScheduler(SCHEDULER).cancel(schedulerCallId);
        emit SchedulerCancelled(schedulerCallId);
        schedulerCallId = 0;
    }

    /// @notice Get scheduler state (0=SCHEDULED, 1=EXECUTING, 2=COMPLETED, 3=CANCELLED, 4=EXPIRED)
    function getSchedulerState() external view returns (uint8) {
        if (schedulerCallId == 0) return 5; // not scheduled
        return IScheduler(SCHEDULER).getCallState(schedulerCallId);
    }

    // ── Manual Fetch (for ad-hoc / testing) ──
    function fetchNow() external returns (bytes memory) {
        return _fetchAndStore();
    }

    // ── Internal ──
    function _fetchAndStore() internal returns (bytes memory) {
        require(executor != address(0), "no executor set");

        string memory url = string.concat(
            "https://clob.polymarket.com/markets?limit=50&closed=false"
        );

        bytes memory encodedInput = abi.encode(
            executor,
            new bytes[](0),
            TTL,
            new bytes[](0),
            bytes(""),
            url,
            uint8(1),           // GET
            new string[](0),
            new string[](0),
            bytes(""),
            uint256(0),         // dkmsKeyIndex
            uint8(0),           // dkmsKeyFormat
            false               // piiEnabled
        );

        (bool ok, bytes memory output) = HTTP_PRECOMPILE.call(encodedInput);
        require(ok, "precompile call failed");

        (uint16 statusCode, , , bytes memory body, string memory errorMessage) =
            abi.decode(output, (uint16, string[], string[], bytes, string));

        // Store in round
        uint256 round = ++fetchCount;
        rounds[round] = MarketSnapshot(block.timestamp, statusCode, body, errorMessage);
        latestRound = round;

        emit MarketDataFetched(round, statusCode, errorMessage, body);

        return body;
    }

    // ── Query ──
    function getLatest() external view returns (uint256, uint16, bytes memory, string memory) {
        MarketSnapshot memory snap = rounds[latestRound];
        return (snap.timestamp, snap.statusCode, snap.body, snap.errorMessage);
    }

    function getRound(uint256 round) external view returns (MarketSnapshot memory) {
        return rounds[round];
    }

    // ── Receive ──
    receive() external payable {}
}

// ── Minimal IScheduler Interface ──
interface IScheduler {
    function schedule(
        bytes memory data,
        uint32 gas,
        uint32 numCalls,
        uint32 frequency
    ) external returns (uint256 callId);
    function cancel(uint256 callId) external;
    function getCallState(uint256 callId) external view returns (uint8);
}
