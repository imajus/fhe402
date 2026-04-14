// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Script} from "forge-std/Script.sol";
import {EncryptedCounter} from "../src/EncryptedCounter.sol";

contract DeployEncryptedCounter is Script {
    function run() public returns (EncryptedCounter counterContract) {
        vm.broadcast();
        counterContract = new EncryptedCounter();
    }
}
