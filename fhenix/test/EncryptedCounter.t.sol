// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Test} from "forge-std/Test.sol";
import {CoFheTest} from "@cofhe/mock-contracts/CoFheTest.sol";
import {FHE, InEuint128, euint128} from "@fhenixprotocol/cofhe-contracts/FHE.sol";
import {EncryptedCounter} from "../src/EncryptedCounter.sol";

contract EncryptedCounterTest is Test, CoFheTest {
    EncryptedCounter private counterContract;

    function setUp() public {
        counterContract = new EncryptedCounter();
    }

    function test_store() public {
        InEuint128 memory num = createInEuint128(10, address(this));
        counterContract.store(num);

        euint128 current = counterContract.getCounter();
        assertHashValue(current, 10);
    }

    function test_increment(uint128 _num, uint128 _inc) public {
        vm.assume(type(uint128).max - _num >= _inc); // prevent overflow

        InEuint128 memory num = createInEuint128(_num, address(this));
        counterContract.store(num);

        InEuint128 memory inc = createInEuint128(_inc, address(this));
        counterContract.increment(inc);

        euint128 current = counterContract.getCounter();
        assertHashValue(current, _num + _inc);
    }

    function test_decrement(uint128 _num, uint128 _dec) public {
        vm.assume(_num >= _dec); // prevent underflow

        InEuint128 memory num = createInEuint128(_num, address(this));
        counterContract.store(num);

        InEuint128 memory dec = createInEuint128(_dec, address(this));
        counterContract.decrement(dec);

        euint128 current = counterContract.getCounter();
        assertHashValue(current, _num - _dec);
    }
}
