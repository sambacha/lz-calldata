
/// SPDX-License-Identifier: MIT
pragma solidity >=0.6.4 <0.9.0;

// @see {@link github.com/ethereum-optimism/contracts/blob/bb91c16d0c4de513a023fb6d4512bfb1a6c85999/contracts/test-helpers/Helper_GasMeasurer.sol}

/// @title GasHarness
contract GasHarness {
    function measureCallGas(
        address _target,
        bytes memory _data
    )
        public
        returns ( uint256 )
    {
        uint256 gasBefore;
        uint256 gasAfter;

        uint256 calldataStart;
        uint256 calldataLength;
        assembly {
            calldataStart := add(_data,0x20)
            calldataLength := mload(_data)
        }

        bool success;
        assembly {
            gasBefore := gas()
            success := call(gas(), _target, 0, calldataStart, calldataLength, 0, 0)
            gasAfter := gas()
        }
        require(success, "#[Err(E)]! kind: measureCallGas failed");
        
        return gasBefore - gasAfter;
    }
}