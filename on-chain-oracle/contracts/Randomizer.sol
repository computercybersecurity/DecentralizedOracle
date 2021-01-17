pragma solidity >=0.4.21 <0.6.0;
// pragma solidity ^0.5.4;


/**
 * Randomizer to generating psuedo random numbers
 */
contract Randomizer {
    function getRandom(uint gamerange) external view returns (uint)
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

    function getRandom(uint gamerange, uint seed) external view returns (uint)
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

    function getRandom() external view returns (uint) {
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
