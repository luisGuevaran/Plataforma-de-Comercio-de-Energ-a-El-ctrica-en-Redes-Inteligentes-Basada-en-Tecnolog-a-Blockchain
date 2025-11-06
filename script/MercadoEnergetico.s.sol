// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
// 1. Importa tu contrato
import {MercadoEnergetico} from "../src/MercadoEnergetico.sol";

contract MercadoEnergeticoScript is Script {
    function setUp() public {}

    function run() public {
        // 2. Obtiene la llave privada del "desplegador" desde Anvil
        uint256 deployerPrivateKey = vm.envOr("PRIVATE_KEY", uint256(0)); 

        // 3. Empieza a "transmitir" transacciones
        vm.startBroadcast(deployerPrivateKey);

        // 4. Despliega el contrato
        MercadoEnergetico mercado = new MercadoEnergetico();

        // 5. Deja de transmitir
        vm.stopBroadcast();

        // 6. Imprime la dirección para que la podamos usar en Python
        console.log("Contrato MercadoEnergetico desplegado en:", address(mercado));
    }
}