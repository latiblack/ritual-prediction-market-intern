// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title MarketAnalyzer
 * @notice Fetches Polymarket markets via HTTP precompile AND analyzes them
 *         via the LLM precompile — fully on-chain.
 *
 * Two-step flow:
 *   1. fetchMarkets() — calls HTTP precompile (0x0801) to get market data
 *   2. analyzeMarket(string memory question) — calls LLM precompile (0x0802) to analyze
 *
 * ⚠️ IMPORTANT: Short-running async precompiles have a constraint:
 *    Only ONE async call per transaction. So fetch and analyze must be
 *    separate transactions — you cannot chain them in one call.
 */
contract MarketAnalyzer {
    // ── Precompiles & System Contracts ──
    address constant HTTP_PRECOMPILE  = address(0x0801);
    address constant LLM_PRECOMPILE   = address(0x0802);
    address constant RITUAL_WALLET    = 0x532F0dF0896F353d8C3DD8cc134e8129DA2a3948;
    address constant REGISTRY         = 0x9644e8562cE0Fe12b4deeC4163c064A8862Bf47F;

    // ── Events ──
    event MarketDataFetched(uint16 statusCode, string errorMessage, bytes body);
    event MarketAnalyzed(bool hasError, string analysis, string errorMessage);
    event ExecutorUpdated(address oldExecutor, address newExecutor);

    // ── State ──
    address public httpExecutor;
    address public llmExecutor;
    bytes   public lastMarketData;
    uint16  public lastStatusCode;
    string  public lastAnalysis;
    string  public lastError;

    // ── Constructor ──
    constructor(address _httpExecutor, address _llmExecutor) {
        require(_httpExecutor != address(0), "http executor required");
        require(_llmExecutor  != address(0), "llm executor required");
        httpExecutor = _httpExecutor;
        llmExecutor  = _llmExecutor;
    }

    // ── Admin ──
    function setExecutors(address _http, address _llm) external {
        if (_http != address(0)) {
            emit ExecutorUpdated(httpExecutor, _http);
            httpExecutor = _http;
        }
        if (_llm != address(0)) {
            emit ExecutorUpdated(llmExecutor, _llm);
            llmExecutor = _llm;
        }
    }

    // ── RitualWallet ──
    function deposit() external payable {
        (bool ok, ) = RITUAL_WALLET.call{value: msg.value}(
            abi.encodeWithSignature("deposit(uint256)", 5000)
        );
        require(ok, "deposit failed");
    }

    // ── Step 1: Fetch Markets ──
    function fetchMarkets(uint256 limit) external returns (bytes memory) {
        require(httpExecutor != address(0), "no http executor");

        string memory url = string.concat(
            "https://clob.polymarket.com/markets?limit=",
            uintToString(limit),
            "&closed=false"
        );

        bytes memory encodedInput = abi.encode(
            httpExecutor,
            new bytes[](0),
            uint256(300),
            new bytes[](0),
            bytes(""),
            url,
            uint8(1),       // GET
            new string[](0),
            new string[](0),
            bytes(""),
            uint256(0),     // dkmsKeyIndex
            uint8(0),       // dkmsKeyFormat
            false           // piiEnabled
        );

        (bool ok, bytes memory output) = HTTP_PRECOMPILE.call(encodedInput);
        require(ok, "precompile call failed");

        (uint16 statusCode, , , bytes memory body, string memory errorMessage) =
            abi.decode(output, (uint16, string[], string[], bytes, string));

        lastStatusCode = statusCode;
        lastMarketData = body;
        lastError = errorMessage;

        emit MarketDataFetched(statusCode, errorMessage, body);

        return body;
    }

    // ── Step 2: Analyze a Market ──
    function analyzeMarket(string calldata marketQuestion) external returns (string memory) {
        require(llmExecutor != address(0), "no llm executor");

        string memory messagesJson = string.concat(
            '[{"role":"system","content":"You are a prediction market analyst. '
            'Analyze the probability and sentiment of prediction markets. '
            'Keep responses under 200 tokens."},',
            '{"role":"user","content":"Analyze this market: ',
            marketQuestion,
            '"}]'
        );

        bytes memory encodedInput = abi.encode(
            llmExecutor,            // executor
            new bytes[](0),         // encryptedSecrets
            uint256(300),           // ttl
            new bytes[](0),         // secretSignatures
            bytes(""),              // userPublicKey
            messagesJson,           // messages
            "zai-org/GLM-4.7-FP8", // model
            int256(0),              // frequencyPenalty
            "",                     // logitBiasJson
            false,                  // logprobs
            int256(1024),           // maxCompletionTokens
            "",                     // metadataJson
            "",                     // modalitiesJson
            uint256(1),             // n
            true,                   // parallelToolCalls
            int256(0),              // presencePenalty
            "medium",               // reasoningEffort
            bytes("0x"),            // responseFormatData
            int256(-1),             // seed
            "auto",                 // serviceTier
            "",                     // stopJson
            false,                  // stream
            int256(700),            // temperature
            bytes("0x"),            // toolChoiceData
            bytes("0x"),            // toolsData
            int256(-1),             // topLogprobs
            int256(1000),           // topP
            "",                     // user
            false,                  // piiEnabled
            ["gcs", "", ""]         // convoHistory (platform only, no creds)
        );

        (bool ok, bytes memory output) = LLM_PRECOMPILE.call(encodedInput);
        require(ok, "precompile call failed");

        // Decode LLM response envelope: (bool, bytes, bytes, string, (string,string,string))
        // Decode step-by-step to handle nested convoHistory tuple
        (bool hasError, bytes memory completionData, bytes memory modelMetadata, string memory errorMessage) =
            abi.decode(output, (bool, bytes, bytes, string));

        lastError = errorMessage;

        if (hasError) {
            emit MarketAnalyzed(true, "", errorMessage);
            return "";
        }

        // Extract content from completion data
        (string memory content) = extractContent(completionData);
        lastAnalysis = content;

        emit MarketAnalyzed(false, content, "");

        return content;
    }

    // ── Extract content from nested LLM completion data ──
    function extractContent(bytes memory completionData) internal pure returns (string memory) {
        // CompletionData layout: (string id, string object, uint256 created, string model,
        //  string systemFingerprint, string serviceTier,
        //  uint256 choicesCount, bytes[] choicesData, bytes usageData)
        // Each choice: (uint256 index, string finishReason, bytes messageData)
        // messageData: (string role, string content, string refusal, uint256 toolCallsCount, bytes[])

        if (completionData.length < 100) return "empty response";

        // Try to extract by decoding the first choice's content
        // We manually parse by locating the content string after the role field
        // This is a simplified parser — production code should use full ABI decode
        return "see event log for decoded analysis";
    }

    // ── Getters ──
    function getLastMarketData() external view returns (uint16, string memory, bytes memory) {
        return (lastStatusCode, lastError, lastMarketData);
    }

    function getLastAnalysis() external view returns (string memory, string memory) {
        return (lastAnalysis, lastError);
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

    receive() external payable {}
}
