// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Higher} from "../src/Higher.sol";

contract HigherScript is Script {

    address public yungwknd = 0x6140F00e4Ff3936702E68744f2b5978885464cbB;
    function setUp() public {}

    function run() public {
        (address addy, uint256 key) = makeAddrAndKey("higherandhigher");

        vm.startBroadcast(key);

        console.log(addy);

        new Higher();

        vm.stopBroadcast();
    }
}