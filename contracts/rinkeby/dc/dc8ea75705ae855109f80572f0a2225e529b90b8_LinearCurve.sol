/**
 *Submitted for verification at Etherscan.io on 2022-07-17
*/

// File: lssvm/bondingcurve/FixedPointMathLib.sol


pragma solidity >=0.8.0;

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/FixedPointMathLib.sol)
library FixedPointMathLib {
    /*///////////////////////////////////////////////////////////////
                            COMMON BASE UNITS
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant YAD = 1e8;
    uint256 internal constant WAD = 1e18;
    uint256 internal constant RAY = 1e27;
    uint256 internal constant RAD = 1e45;

    /*///////////////////////////////////////////////////////////////
                         FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function fmul(
        uint256 x,
        uint256 y,
        uint256 baseUnit
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(x == 0 || (x * y) / x == y)
            if iszero(or(iszero(x), eq(div(z, x), y))) {
                revert(0, 0)
            }

            // If baseUnit is zero this will return zero instead of reverting.
            z := div(z, baseUnit)
        }
    }

    function fdiv(
        uint256 x,
        uint256 y,
        uint256 baseUnit
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * baseUnit in z for now.
            z := mul(x, baseUnit)

            // Equivalent to require(y != 0 && (x == 0 || (x * baseUnit) / x == baseUnit))
            if iszero(and(iszero(iszero(y)), or(iszero(x), eq(div(z, x), baseUnit)))) {
                revert(0, 0)
            }

            // We ensure y is not zero above, so there is never division by zero here.
            z := div(z, y)
        }
    }

    function fpow(
        uint256 x,
        uint256 n,
        uint256 baseUnit
    ) internal pure returns (uint256 z) {
        assembly {
            switch x
            case 0 {
                switch n
                case 0 {
                    // 0 ** 0 = 1
                    z := baseUnit
                }
                default {
                    // 0 ** n = 0
                    z := 0
                }
            }
            default {
                switch mod(n, 2)
                case 0 {
                    // If n is even, store baseUnit in z for now.
                    z := baseUnit
                }
                default {
                    // If n is odd, store x in z for now.
                    z := x
                }

                // Shifting right by 1 is like dividing by 2.
                let half := shr(1, baseUnit)

                for {
                    // Shift n right by 1 before looping to halve it.
                    n := shr(1, n)
                } n {
                    // Shift n right by 1 each iteration to halve it.
                    n := shr(1, n)
                } {
                    // Revert immediately if x ** 2 would overflow.
                    // Equivalent to iszero(eq(div(xx, x), x)) here.
                    if shr(128, x) {
                        revert(0, 0)
                    }

                    // Store x squared.
                    let xx := mul(x, x)

                    // Round to the nearest number.
                    let xxRound := add(xx, half)

                    // Revert if xx + half overflowed.
                    if lt(xxRound, xx) {
                        revert(0, 0)
                    }

                    // Set x to scaled xxRound.
                    x := div(xxRound, baseUnit)

                    // If n is even:
                    if mod(n, 2) {
                        // Compute z * x.
                        let zx := mul(z, x)

                        // If z * x overflowed:
                        if iszero(eq(div(zx, x), z)) {
                            // Revert if x is non-zero.
                            if iszero(iszero(x)) {
                                revert(0, 0)
                            }
                        }

                        // Round to the nearest number.
                        let zxRound := add(zx, half)

                        // Revert if zx + half overflowed.
                        if lt(zxRound, zx) {
                            revert(0, 0)
                        }

                        // Return properly scaled zxRound.
                        z := div(zxRound, baseUnit)
                    }
                }
            }
        }
    }

    /*///////////////////////////////////////////////////////////////
                        GENERAL NUMBER UTILITIES
    //////////////////////////////////////////////////////////////*/

    function sqrt(uint256 x) internal pure returns (uint256 z) {
        assembly {
            // Start off with z at 1.
            z := 1

            // Used below to help find a nearby power of 2.
            let y := x

            // Find the lowest power of 2 that is at least sqrt(x).
            if iszero(lt(y, 0x100000000000000000000000000000000)) {
                y := shr(128, y) // Like dividing by 2 ** 128.
                z := shl(64, z)
            }
            if iszero(lt(y, 0x10000000000000000)) {
                y := shr(64, y) // Like dividing by 2 ** 64.
                z := shl(32, z)
            }
            if iszero(lt(y, 0x100000000)) {
                y := shr(32, y) // Like dividing by 2 ** 32.
                z := shl(16, z)
            }
            if iszero(lt(y, 0x10000)) {
                y := shr(16, y) // Like dividing by 2 ** 16.
                z := shl(8, z)
            }
            if iszero(lt(y, 0x100)) {
                y := shr(8, y) // Like dividing by 2 ** 8.
                z := shl(4, z)
            }
            if iszero(lt(y, 0x10)) {
                y := shr(4, y) // Like dividing by 2 ** 4.
                z := shl(2, z)
            }
            if iszero(lt(y, 0x8)) {
                // Equivalent to 2 ** z.
                z := shl(1, z)
            }

            // Shifting right by 1 is like dividing by 2.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // Compute a rounded down version of z.
            let zRoundDown := div(x, z)

            // If zRoundDown is smaller, use it.
            if lt(zRoundDown, z) {
                z := zRoundDown
            }
        }
    }
}
// File: lssvm/bondingcurve/CurveErrorCodes.sol


pragma solidity ^0.8.0;

contract CurveErrorCodes {
    enum Error {
        OK, // No error
        INVALID_NUMITEMS, // The numItem value is 0
        SPOT_PRICE_OVERFLOW // The updated spot price doesn't fit into 128 bits
    }
}

// File: lssvm/bondingcurve/ICurve.sol


pragma solidity ^0.8.0;


interface ICurve {
    /**
        @notice Validates if a delta value is valid for the curve. The criteria for
        validity can be different for each type of curve, for instance ExponentialCurve
        requires delta to be greater than 1.
        @param delta The delta value to be validated
        @return valid True if delta is valid, false otherwise
     */
    function validateDelta(uint128 delta) external pure returns (bool valid);

    /**
        @notice Validates if a new spot price is valid for the curve. Spot price is generally assumed to be the immediate sell price of 1 NFT to the pool, in units of the pool's paired token.
        @param newSpotPrice The new spot price to be set
        @return valid True if the new spot price is valid, false otherwise
     */
    function validateSpotPrice(uint128 newSpotPrice)
        external
        view
        returns (bool valid);

    /**
        @notice Given the current state of the pair and the trade, computes how much the user
        should pay to purchase an NFT from the pair, the new spot price, and other values.
        @param spotPrice The current selling spot price of the pair, in tokens
        @param delta The delta parameter of the pair, what it means depends on the curve
        @param numItems The number of NFTs the user is buying from the pair
        @param feeMultiplier Determines how much fee the LP takes from this trade, 18 decimals
        @param protocolFeeMultiplier Determines how much fee the protocol takes from this trade, 18 decimals
        @return error Any math calculation errors, only Error.OK means the returned values are valid
        @return newSpotPrice The updated selling spot price, in tokens
        @return newDelta The updated delta, used to parameterize the bonding curve
        @return inputValue The amount that the user should pay, in tokens
        @return protocolFee The amount of fee to send to the protocol, in tokens
     */
    function getBuyInfo(
        uint128 spotPrice,
        uint128 delta,
        uint256 numItems,
        uint256 feeMultiplier,
        uint256 protocolFeeMultiplier
    )
        external
        view
        returns (
            CurveErrorCodes.Error error,
            uint128 newSpotPrice,
            uint128 newDelta,
            uint256 inputValue,
            uint256 protocolFee
        );

    /**
        @notice Given the current state of the pair and the trade, computes how much the user
        should receive when selling NFTs to the pair, the new spot price, and other values.
        @param spotPrice The current selling spot price of the pair, in tokens
        @param delta The delta parameter of the pair, what it means depends on the curve
        @param numItems The number of NFTs the user is selling to the pair
        @param feeMultiplier Determines how much fee the LP takes from this trade, 18 decimals
        @param protocolFeeMultiplier Determines how much fee the protocol takes from this trade, 18 decimals
        @return error Any math calculation errors, only Error.OK means the returned values are valid
        @return newSpotPrice The updated selling spot price, in tokens
        @return newDelta The updated delta, used to parameterize the bonding curve
        @return outputValue The amount that the user should receive, in tokens
        @return protocolFee The amount of fee to send to the protocol, in tokens
     */
    function getSellInfo(
        uint128 spotPrice,
        uint128 delta,
        uint256 numItems,
        uint256 feeMultiplier,
        uint256 protocolFeeMultiplier
    )
        external
        view
        returns (
            CurveErrorCodes.Error error,
            uint128 newSpotPrice,
            uint128 newDelta,
            uint256 outputValue,
            uint256 protocolFee
        );
}

// File: lssvm/bondingcurve/LinearCurve.sol


pragma solidity ^0.8.0;




/*
    @author 0xmons and boredGenius
    @notice Bonding curve logic for a linear curve, where each buy/sell changes spot price by adding/substracting delta
*/
contract LinearCurve is ICurve, CurveErrorCodes {
    using FixedPointMathLib for uint256;

    /**
        @dev See {ICurve-validateDelta}
     */
    function validateDelta(
        uint128 /*delta*/
    ) external pure override returns (bool valid) {
        // For a linear curve, all values of delta are valid
        return true;
    }

    /**
        @dev See {ICurve-validateSpotPrice}
     */
    function validateSpotPrice(
        uint128 /* newSpotPrice */
    ) external pure override returns (bool) {
        // For a linear curve, all values of spot price are valid
        return true;
    }

    /**
        @dev See {ICurve-getBuyInfo}
     */
    function getBuyInfo(
        uint128 spotPrice,
        uint128 delta,
        uint256 numItems,
        uint256 feeMultiplier,
        uint256 protocolFeeMultiplier
    )
        external
        pure
        override
        returns (
            Error error,
            uint128 newSpotPrice,
            uint128 newDelta,
            uint256 inputValue,
            uint256 protocolFee
        )
    {
        // We only calculate changes for buying 1 or more NFTs
        if (numItems == 0) {
            return (Error.INVALID_NUMITEMS, 0, 0, 0, 0);
        }

        // For a linear curve, the spot price increases by delta for each item bought
        uint256 newSpotPrice_ = spotPrice + delta * numItems;
        if (newSpotPrice_ > type(uint128).max) {
            return (Error.SPOT_PRICE_OVERFLOW, 0, 0, 0, 0);
        }
        newSpotPrice = uint128(newSpotPrice_);

        // Spot price is assumed to be the instant sell price. To avoid arbitraging LPs, we adjust the buy price upwards.
        // If spot price for buy and sell were the same, then someone could buy 1 NFT and then sell for immediate profit.
        // EX: Let S be spot price. Then buying 1 NFT costs S ETH, now new spot price is (S+delta).
        // The same person could then sell for (S+delta) ETH, netting them delta ETH profit.
        // If spot price for buy and sell differ by delta, then buying costs (S+delta) ETH.
        // The new spot price would become (S+delta), so selling would also yield (S+delta) ETH.
        uint256 buySpotPrice = spotPrice + delta;

        // If we buy n items, then the total cost is equal to:
        // (buy spot price) + (buy spot price + 1*delta) + (buy spot price + 2*delta) + ... + (buy spot price + (n-1)*delta)
        // This is equal to n*(buy spot price) + (delta)*(n*(n-1))/2
        // because we have n instances of buy spot price, and then we sum up from delta to (n-1)*delta
        inputValue =
            numItems *
            buySpotPrice +
            (numItems * (numItems - 1) * delta) /
            2;

        // Account for the protocol fee, a flat percentage of the buy amount
        protocolFee = inputValue.fmul(
            protocolFeeMultiplier,
            FixedPointMathLib.WAD
        );

        // Account for the trade fee, only for Trade pools
        inputValue += inputValue.fmul(feeMultiplier, FixedPointMathLib.WAD);

        // Add the protocol fee to the required input amount
        inputValue += protocolFee;

        // Keep delta the same
        newDelta = delta;

        // If we got all the way here, no math error happened
        error = Error.OK;
    }

    /**
        @dev See {ICurve-getSellInfo}
     */
    function getSellInfo(
        uint128 spotPrice,
        uint128 delta,
        uint256 numItems,
        uint256 feeMultiplier,
        uint256 protocolFeeMultiplier
    )
        external
        pure
        override
        returns (
            Error error,
            uint128 newSpotPrice,
            uint128 newDelta,
            uint256 outputValue,
            uint256 protocolFee
        )
    {
        // We only calculate changes for selling 1 or more NFTs
        if (numItems == 0) {
            return (Error.INVALID_NUMITEMS, 0, 0, 0, 0);
        }

        // We first calculate the change in spot price after selling all of the items
        uint256 totalPriceDecrease = delta * numItems;

        // If the current spot price is less than the total amount that the spot price should change by...
        if (spotPrice < totalPriceDecrease) {
            // Then we set the new spot price to be 0. (Spot price is never negative)
            newSpotPrice = 0;

            // We calculate how many items we can sell into the linear curve until the spot price reaches 0, rounding up
            uint256 numItemsTillZeroPrice = spotPrice / delta + 1;
            numItems = numItemsTillZeroPrice;
        }
        // Otherwise, the current spot price is greater than or equal to the total amount that the spot price changes
        // Thus we don't need to calculate the maximum number of items until we reach zero spot price, so we don't modify numItems
        else {
            // The new spot price is just the change between spot price and the total price change
            newSpotPrice = spotPrice - uint128(totalPriceDecrease);
        }

        // If we sell n items, then the total sale amount is:
        // (spot price) + (spot price - 1*delta) + (spot price - 2*delta) + ... + (spot price - (n-1)*delta)
        // This is equal to n*(spot price) - (delta)*(n*(n-1))/2
        outputValue =
            numItems *
            spotPrice -
            (numItems * (numItems - 1) * delta) /
            2;

        // Account for the protocol fee, a flat percentage of the sell amount
        protocolFee = outputValue.fmul(
            protocolFeeMultiplier,
            FixedPointMathLib.WAD
        );

        // Account for the trade fee, only for Trade pools
        outputValue -= outputValue.fmul(feeMultiplier, FixedPointMathLib.WAD);

        // Subtract the protocol fee from the output amount to the seller
        outputValue -= protocolFee;

        // Keep delta the same
        newDelta = delta;

        // If we reached here, no math errors
        error = Error.OK;
    }
}