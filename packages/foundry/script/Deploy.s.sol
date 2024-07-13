//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../contracts/YourContract.sol";
import "../contracts/SwapHook.sol";
import "forge-std/Script.sol";
import "../contracts/WorldcoinVerifier.sol";
import "../contracts/ByteHasher.sol";
import "../contracts/IWorldID.sol";
import "./DeployHelpers.s.sol";

contract DeployScript is ScaffoldETHDeploy {
  error InvalidPrivateKey(string);

  function run() external {
    uint256 deployerPrivateKey = setupLocalhostEnv();
    if (deployerPrivateKey == 0) {
      revert InvalidPrivateKey(
        "You don't have a deployer account. Make sure you have set DEPLOYER_PRIVATE_KEY in .env or use `yarn generate` to generate a new random account"
      );
    }
    vm.startBroadcast(deployerPrivateKey);

    address worldIdRouterAddress = 0x469449f251692E0779667583026b5A1E99512157; // Replace with actual address
    string memory appId = "app_staging_190d34fc743cee705b492dc47e97a5aa"; // Replace with your actual app ID
    string memory actionId = "verify-human"; // Replace with your actual action ID

    WorldcoinVerifier verifier = new WorldcoinVerifier(
        IWorldID(worldIdRouterAddress),
        appId,
        actionId
    );

    console.logString(
        string.concat(
            "WorldcoinVerifier deployed at: ",
            vm.toString(address(verifier))
        )
    );

    YourContract yourContract = new YourContract(vm.addr(deployerPrivateKey));
    console.logString(
      string.concat(
        "YourContract deployed at: ", vm.toString(address(yourContract))
      )
    );

    vm.stopBroadcast();

    /**
     * This function generates the file containing the contracts Abi definitions.
     * These definitions are used to derive the types needed in the custom scaffold-eth hooks, for example.
     * This function should be called last.
     */
    exportDeployments();
  }

  function test() public { }
}
