// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Higher} from "../src/Higher.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v3-core/contracts/interfaces/pool/IUniswapV3PoolState.sol";
import "@uniswap/v3-core/contracts/interfaces/pool/IUniswapV3PoolActions.sol";

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        // 512-bit multiply [prod1 prod0] = a * b
        // Compute the product mod 2**256 and mod 2**256 - 1
        // then use the Chinese Remainder Theorem to reconstruct
        // the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2**256 + prod0
        uint256 prod0; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product
        assembly {
            let mm := mulmod(a, b, not(0))
            prod0 := mul(a, b)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        // Handle non-overflow cases, 256 by 256 division
        if (prod1 == 0) {
            require(denominator > 0);
            assembly {
                result := div(prod0, denominator)
            }
            return result;
        }

        // Make sure the result is less than 2**256.
        // Also prevents denominator == 0
        require(denominator > prod1);

        ///////////////////////////////////////////////
        // 512 by 256 division.
        ///////////////////////////////////////////////

        // Make division exact by subtracting the remainder from [prod1 prod0]
        // Compute remainder using mulmod
        uint256 remainder;
        assembly {
            remainder := mulmod(a, b, denominator)
        }
        // Subtract 256 bit number from 512 bit number
        assembly {
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        // Factor powers of two out of denominator
        // Compute largest power of two divisor of denominator.
        // Always >= 1.
        uint256 twos = denominator & (~denominator + 1);
        // Divide denominator by power of two
        assembly {
            denominator := div(denominator, twos)
        }

        // Divide [prod1 prod0] by the factors of two
        assembly {
            prod0 := div(prod0, twos)
        }
        // Shift in bits from prod1 into prod0. For this we need
        // to flip `twos` such that it is 2**256 / twos.
        // If twos is zero, then it becomes one
        assembly {
            twos := add(div(sub(0, twos), twos), 1)
        }
        prod0 |= prod1 * twos;

        // Invert denominator mod 2**256
        // Now that denominator is an odd number, it has an inverse
        // modulo 2**256 such that denominator * inv = 1 mod 2**256.
        // Compute the inverse by starting with a seed that is correct
        // correct for four bits. That is, denominator * inv = 1 mod 2**4
        uint256 inv = (3 * denominator) ^ 2;
        // Now use Newton-Raphson iteration to improve the precision.
        // Thanks to Hensel's lifting lemma, this also works in modular
        // arithmetic, doubling the correct bits in each step.
        inv *= 2 - denominator * inv; // inverse mod 2**8
        inv *= 2 - denominator * inv; // inverse mod 2**16
        inv *= 2 - denominator * inv; // inverse mod 2**32
        inv *= 2 - denominator * inv; // inverse mod 2**64
        inv *= 2 - denominator * inv; // inverse mod 2**128
        inv *= 2 - denominator * inv; // inverse mod 2**256

        // Because the division is now exact we can divide by multiplying
        // with the modular inverse of denominator. This will give us the
        // correct result modulo 2**256. Since the precoditions guarantee
        // that the outcome is less than 2**256, this is the final result.
        // We don't need to compute the high bits of the result and prod1
        // is no longer required.
        result = prod0 * inv;
        return result;
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        result = mulDiv(a, b, denominator);
        if (mulmod(a, b, denominator) > 0) {
            require(result < type(uint256).max);
            result++;
        }
    }
}


contract HigherTest is Test {
    Higher public h;

    address public yungwknd = 0x6140F00e4Ff3936702E68744f2b5978885464cbB;
    address public uniPool = 0xCC28456d4Ff980CeE3457Ca809a257E52Cd9CDb0;
    IERC20 public hhhContract = IERC20(0x0578d8A44db98B23BF096A382e016e29a5Ce0ffe);

    string alchemy_provider = "https://base-mainnet.g.alchemy.com/v2/";

    uint baseFork;
    uint baseFork2;

    uint forkBlock = 12685812;
    uint forkBlock2 = 12690813;

    function setUp() public {
        baseFork = vm.createFork(alchemy_provider, forkBlock);
        baseFork2 = vm.createFork(alchemy_provider, forkBlock2);
        vm.selectFork(baseFork);
        vm.startPrank(yungwknd);
        // h = new Higher(yungwknd);
        // h.updatePool(uniPool);
        vm.stopPrank();
    }

    function testPrice() public {
        vm.selectFork(baseFork);
        vm.startPrank(yungwknd);

        // assertEq(hhhContract.balanceOf(yungwknd), 591700000000000000000000);

        h = new Higher();
        h.updatePool(uniPool, 10000);
        h.setURI("abcd");

        vm.makePersistent(address(h));
        vm.makePersistent(yungwknd);

        uint lastPrice1 = h.lastPriceBought();

        console.log("BEFORE ANYTHING");
        console.log(lastPrice1);
        console.log(block.number);
        console.log("-----------");

        // lastPriceBought should be 0 to start
        assertEq(lastPrice1, 0);

        vm.expectRevert(Higher.MustGoHigher.selector);
        h.higherMint{value: 0 ether}(1);

        // Should be free (first mint ever)
        uint balanceBefore = address(yungwknd).balance;

        console.log("**************");

        h.higherMint{value: 0.00069 ether}(1);
        uint balanceAfter = address(yungwknd).balance;
        
        assertEq(balanceBefore, balanceAfter);

        console.log(balanceBefore);
        console.log(balanceAfter);

        console.log("**************");
        uint lastPrice2 = h.lastPriceBought();

        console.log("AFTER FIRST MINT");
        console.log(lastPrice2);
        console.log(block.number);
        console.log("-----------");

        // Now it should not be 0
        assert(lastPrice2 != 0);

        // Let's mint again

        assertEq(vm.activeFork(), baseFork);

        // vm.selectFork(baseFork2);

        // assertEq(vm.activeFork(), baseFork2);
        
        // // h = Higher(address(h));

        // // Warp forward a few blocks
        assertEq(hhhContract.balanceOf(yungwknd), 0);

        h.higherMint{value: 0.00069 ether}(1);        

        uint lastPrice3 = h.lastPriceBought();
        console.log("AFTER SECOND MINT");
        console.log(lastPrice3);
        console.log(block.number);
        console.log("-----------");

        assertEq(lastPrice2, lastPrice3);

        vm.stopPrank();

        // Make sure it is the right uri and whatnot...
        assertEq(h.uri(1), "abcd");

        // Make sure yungwknd owns 1 copy of it
        // assertEq(h.balanceOf(yungwknd, 1), 1);

        // Can't setURI if not owner
        vm.expectRevert();
        h.setURI("efgh");

        // Cannot withdraw if not owner
        vm.expectRevert();
        h.withdrawHigher();

        // Cannot withdraw too early
        vm.startPrank(yungwknd);
        vm.expectRevert(Higher.TimelockNotExpired.selector);
        h.withdrawHigher();

        // Warp forward 70 days
        vm.warp(block.timestamp + 70 days);

        // Can withdraw now
        h.withdrawHigher();

        // Make sure it is all gone
        assertEq(hhhContract.balanceOf(address(h)), 0);

        // Make sure yungwknd has it all
        assertEq(hhhContract.balanceOf(yungwknd), 25651830707224532008);

        vm.stopPrank();
    }

    function testLogicWithRollFork() public {
        uint forkBlock = 12686077;
        uint forkBlock2 = forkBlock+100;
        uint baseFork = vm.createFork(alchemy_provider, forkBlock);

        vm.selectFork(baseFork);

        IUniswapV3PoolState poolState = IUniswapV3PoolState(uniPool);
        (uint160 sqrtPriceX96,,,,,,) = poolState.slot0();
        uint256 numerator = uint256(sqrtPriceX96) * uint256(sqrtPriceX96);
        uint256 firstPrice = FullMath.mulDiv(numerator, 10**18, 1 << 192);

        console.log("FIRST PRICE");
        console.log(firstPrice);

        vm.rollFork(forkBlock2);
        vm.warp(block.timestamp+100);

        IUniswapV3PoolState poolState2 = IUniswapV3PoolState(uniPool);
        (uint160 sqrtPriceX962,,,,,,) = poolState2.slot0();
        uint256 numerator2 = uint256(sqrtPriceX962) * uint256(sqrtPriceX962);
        uint256 secondPrice = FullMath.mulDiv(numerator2, 10**18, 1 << 192);

        console.log("NEW PRICE");
        console.log(secondPrice);

        assertEq(firstPrice, secondPrice);
    }

    function testLogicWithChangeFork() public {
        uint forkBlock = 12686077;
        uint forkBlock2 = forkBlock+100;
        uint baseFork = vm.createFork(alchemy_provider, forkBlock);
        uint baseFork2 = vm.createFork(alchemy_provider, forkBlock2);

        vm.selectFork(baseFork);

        IUniswapV3PoolState poolState = IUniswapV3PoolState(uniPool);
        (uint160 sqrtPriceX96,,,,,,) = poolState.slot0();
        uint256 numerator = uint256(sqrtPriceX96) * uint256(sqrtPriceX96);
        uint256 firstPrice = FullMath.mulDiv(numerator, 10**18, 1 << 192);

        console.log("FIRST PRICE");
        console.log(firstPrice);

        vm.selectFork(baseFork2);

        IUniswapV3PoolState poolState2 = IUniswapV3PoolState(uniPool);
        (uint160 sqrtPriceX962,,,,,,) = poolState2.slot0();
        uint256 numerator2 = uint256(sqrtPriceX962) * uint256(sqrtPriceX962);
        uint256 secondPrice = FullMath.mulDiv(numerator2, 10**18, 1 << 192);

        console.log("NEW PRICE");
        console.log(secondPrice);

        assertNotEq(firstPrice, secondPrice);
    }

    function testWithdraw() public {

        vm.startPrank(yungwknd);

        h = new Higher();
        vm.makePersistent(address(h));

        uint timelockStart = h.timelockStart();
        vm.assertEq(timelockStart, block.timestamp);
        console.log("STARTING TIME");
        console.log(timelockStart);

        h.updatePool(uniPool, 10000);
        h.setURI("abcd");
        h.higherMint{value: 0.00069 ether}(1);

        vm.expectRevert(Higher.TimelockNotExpired.selector);
        h.withdrawHigher();

        vm.warp(block.timestamp + 180 days);

        timelockStart = h.timelockStart();
        vm.assertNotEq(timelockStart, block.timestamp);

        // Just warped
        console.log("WARPED");
        console.log(block.timestamp);
        console.log(timelockStart);


        timelockStart = h.timelockStart();
        console.log(block.timestamp);
        console.log(timelockStart + 69 days);
        vm.assertTrue(block.timestamp >= timelockStart + 69 days);

        h.withdrawHigher();

        vm.stopPrank();
    }
}
