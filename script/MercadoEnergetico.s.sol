// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
// 1. Importa tu contrato actualizado
import {MercadoEnergetico} from "../src/MercadoEnergetico.sol";

contract MercadoEnergeticoScript is Script {
    function setUp() public {}

    function run() public {
        // 2. Obtiene la llave privada del "desplegador" (Anvil Cuenta #0)
        uint256 deployerPrivateKey = vm.envOr("PRIVATE_KEY", uint256(0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80)); 
        
        // 3. --- Definir los parámetros del constructor ---
        
        // Usaremos la Cuenta #9 de Anvil como el DSO
        // (Puedes cambiar esta dirección por la que quieras)
        address dso = 0x23618E81e3F5Ec44dc003C714caCF7EA8b57C203;
        uint fee = 3; // Tarifa del 3%

        // 4. Empieza a "transmitir" transacciones
        vm.startBroadcast(deployerPrivateKey);

        // 5. Despliega el contrato PASANDO LOS ARGUMENTOS
        MercadoEnergetico mercado = new MercadoEnergetico(dso, fee);

        // 6. Deja de transmitir
        vm.stopBroadcast();

        // 7. Imprime la información
        console.log("Contrato MercadoEnergetico desplegado en:", address(mercado));
        console.log("-> DSO Address (Cuenta #9):", dso);
        console.log("-> Tarifa de Red (gridFeePercentage):", fee, "%");
    }
}