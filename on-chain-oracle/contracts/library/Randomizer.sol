// pragma solidity >=0.4.21 <0.6.0;
pragma solidity >=0.6.6;


/**
 * Randomizer to generating psuedo random numbers
 */
contract Randomizer {
    function getRandom(uint gamerange) internal view returns (uint)
    {
        return
            uint(
                keccak256(
                    abi.encodePacked(
                        block.timestamp +
                            block.difficulty +
                            uint(keccak256(abi.encodePacked(block.coinbase)))
                    )
                )
            ) % gamerange;
    }

    function getRandom(uint gamerange, uint seed) internal view returns (uint)
    {
        return
            uint(
                keccak256(
                    abi.encodePacked(
                        now +
                            block.difficulty +
                            uint(
                                keccak256(abi.encodePacked(block.coinbase))
                            ) +
                            seed
                    )
                )
            ) % gamerange;
    }

    function getRandom() internal view returns (uint) {
        return
            uint(
                keccak256(
                    abi.encodePacked(
                        block.timestamp +
                            block.difficulty +
                            uint(keccak256(abi.encodePacked(block.coinbase)))
                    )
                )
            );
    }
}
