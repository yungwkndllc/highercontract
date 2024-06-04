// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/// @author: yungwknd

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ERC1155 } from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import { ERC1155Burnable } from "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import { ERC1155Supply } from "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@uniswap/v3-core/contracts/interfaces/pool/IUniswapV3PoolState.sol";

import "./Interfaces.sol";
import "./FullMath.sol";

// ↑↑↑ yungwknd ↑↑↑
contract Higher is ERC1155, Ownable, ERC1155Burnable, ERC1155Supply, ReentrancyGuard {
    error MustGoHigher(); // ↑
    error TimelockNotExpired(); // ⏰

    uint256 public lastPriceBought;
    address public pool;
    address public higher = 0x0578d8A44db98B23BF096A382e016e29a5Ce0ffe;
    address public weth = 0x4200000000000000000000000000000000000006;

    address constant swapRouter = 0x2626664c2603336E57B271c5C0b26F421741e481;
    ISwapRouter02 private constant router = ISwapRouter02(swapRouter);
    uint24 poolFee = 10000;

    uint public timelockStart;
    uint public cost = 0.00069 ether;

    constructor() ERC1155("higher") Ownable(0x6140F00e4Ff3936702E68744f2b5978885464cbB) {
        timelockStart = block.timestamp;
         _mint(msg.sender, 1, 1, unicode"↑");
    }

    function higherMint(uint howMany) nonReentrant public payable {
        if (msg.value != howMany * cost) revert MustGoHigher();

        // First, check the price of $higher on uniswap
        IUniswapV3PoolState poolState = IUniswapV3PoolState(pool);
        (uint160 sqrtPriceX96,,,,,,) = poolState.slot0();
        uint256 numerator = uint256(sqrtPriceX96) * uint256(sqrtPriceX96);
        uint256 realPrice = FullMath.mulDiv(numerator, 10**18, 1 << 192);

        // if realPrice > lastPriceBought then it's free, refund
        if (realPrice > lastPriceBought) {
            lastPriceBought = realPrice;
            payable(msg.sender).transfer(msg.value);
        } else { // otherwise, buy $higher with the eth
            // First, swap the eth for weth
            IWETH9(weth).deposit{value: uint256(msg.value)}();
            IWETH9(weth).approve(swapRouter, msg.value);

            ISwapRouter02.ExactInputSingleParams memory params = ISwapRouter02
                .ExactInputSingleParams({
                    tokenIn: weth,
                    tokenOut: higher,
                    fee: poolFee,
                    recipient: address(this),
                    amountIn: msg.value,
                    amountOutMinimum: 0,
                    sqrtPriceLimitX96: 0
                });

            router.exactInputSingle(params);
        }
        // Mint tokens to them
        _mint(msg.sender, 1, howMany, "");
    }

    function updatePool(address _pool, uint24 _poolFee) public onlyOwner {
        pool = _pool;
        poolFee = _poolFee;
    }

    function withdrawHigher() public onlyOwner {
        if (block.timestamp < timelockStart + 69 days) revert TimelockNotExpired();
        IERC20(higher).transfer(msg.sender, IERC20(higher).balanceOf(address(this)));
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function _update(address from, address to, uint256[] memory ids, uint256[] memory values)
        internal
        override(ERC1155, ERC1155Supply)
    {
        super._update(from, to, ids, values);
    }
}
