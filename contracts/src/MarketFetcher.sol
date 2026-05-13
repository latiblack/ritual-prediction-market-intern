// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title MarketFetcher
 * @notice Fetches Polymarket market data on-chain via Ritual's HTTP precompile (0x0801).
 *
 * Deployment flow:
 *   1. Deploy this contract
 *   2. Deposit RITUAL into RitualWallet (run deposit()
 *   3. Call fetchMarkets() with an executor address from TEEServiceRegistry
 *
 * The HTTP precompile is short-running async: the builder creates a commitment,
 * a TEE executor performs the HTTP call off-chain, and the result is settled
 * via fulfilled replay in the same tx.
 */
contract MarketFetcher {
    // ── Precompiles & System Contracts ──
    address constant HTTP_PRECOMPILE = address(0x0801);
    address constant RITUAL_WALLET    = 0x532F0dF0896F353d8C3DD8cc134e8129DA2a3948;
    address constant REGISTRY         = 0x9644e8562cE0Fe12b4deeC4163c064A8862Bf47F;

    // ── Events ──
    event MarketDataFetched(uint16 statusCode, string errorMessage, bytes body);
    event ExecutorUpdated(address oldExecutor, address newExecutor);

    // ── State ──
    address public executor;
    bytes   public lastResponseBody;
    uint16  public lastStatusCode;
    string  public lastErrorMessage;

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

    // ── RitualWallet ──
    function deposit() external payable {
        (bool ok, ) = RITUAL_WALLET.call{value: msg.value}(
            abi.encodeWithSignature("deposit(uint256)", 5000)
        );
        require(ok, "deposit failed");
    }

    // ── HTTP Precompile: Fetch Polymarket Markets ──
    function fetchMarkets(uint256 limit) external returns (bytes memory) {
        require(executor != address(0), "no executor set");

        // URL: Polymarket CLOB API
        string memory url = string.concat(
            "https://clob.polymarket.com/markets?limit=",
            uintToString(limit),
            "&closed=false"
        );

        // Encode the 13-field HTTP call request
        bytes memory encodedInput = abi.encode(
            executor,           // address executor
            new bytes[](0),     // bytes[] encryptedSecrets
            uint256(300),       // uint256 ttl (blocks)
            new bytes[](0),     // bytes[] secretSignatures
            bytes(""),          // bytes userPublicKey
            url,                // string url
            uint8(1),           // uint8 method (1 = GET)
            new string[](0),    // string[] headerKeys
            new string[](0),    // string[] headerValues
            bytes(""),          // bytes body
            uint256(0),         // uint256 dkmsKeyIndex
            uint8(0),           // uint8 dkmsKeyFormat
            false               // bool piiEnabled
        );

        // Call the HTTP precompile
        (bool ok, bytes memory output) = HTTP_PRECOMPILE.call(encodedInput);
        require(ok, "precompile call failed");

        // Decode response (5-field HTTP response envelope)
        (uint16 statusCode, , , bytes memory body, string memory errorMessage) =
            abi.decode(output, (uint16, string[], string[], bytes, string));

        lastStatusCode = statusCode;
        lastResponseBody = body;
        lastErrorMessage = errorMessage;

        emit MarketDataFetched(statusCode, errorMessage, body);

        return body;
    }

    // ── Query: Last Result ──
    function getLastResult() external view returns (uint16, string memory, bytes memory) {
        return (lastStatusCode, lastErrorMessage, lastResponseBody);
    }

    // ── Helpers ──
    function uintToString(uint256 v) internal pure returns (string memory) {
        if (v == 0) return "0";
        uint256 len;
        uint256 tmp = v;
        while (tmp != 0) { len++; tmp /= 10; }
        bytes memory b = new bytes(len);
        while (v != 0) { b[--len] = bytes1(uint8(48 + v % 10)); v /= 10; }
        return string(b);
    }

    // ── Receive (for RitualWallet deposits) ──
    receive() external payable {}
}
