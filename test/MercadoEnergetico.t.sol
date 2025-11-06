// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
// 1. Importa tu nuevo contrato
import {MercadoEnergetico} from "../src/MercadoEnergetico.sol";

contract MercadoEnergeticoTest is Test {

    // -----------
    // Variables de Estado para la Prueba
    // -----------

    MercadoEnergetico public mercado;

    // Definimos actores para la simulación
    // LÍNEAS NUEVAS (CORRECTAS)
    address public prosumidor = vm.addr(1); // Actor 1
    address public consumidor = vm.addr(2); // Actor 2
    // -----------
    // Configuración (Setup)
    // -----------

    // Esta función se ejecuta ANTES de cada prueba
    function setUp() public {
        // 1. Despliega una nueva instancia del contrato
        mercado = new MercadoEnergetico();
    }

    // -----------
    // Pruebas (Simulaciones)
    // -----------

    /**
     * @dev Prueba que un prosumidor pueda publicar una oferta.
     */
   /**
     * @dev Prueba que un prosumidor pueda publicar una oferta.
     */
    function test_PublicarOferta() public {
        // 1. "Simulamos" ser el PROSUMIDOR
        vm.prank(prosumidor);

        // 2. El prosumidor llama a la función
        mercado.publicarOferta(100, 15); // Vende 100 kWh a 15 wei/kWh

        // 3. Verificamos el resultado
        //
        // ----- ¡ESTA ES LA SECCIÓN CORREGIDA! -----
        // Obtenemos los 5 campos por separado
        (uint idOferta, address prosumidorOferta, uint kwhOferta, uint precioOferta, bool activaOferta) = mercado.ofertas(1);

        // 4. Comparamos las variables individuales
        assertEq(idOferta, 1);
        assertEq(prosumidorOferta, prosumidor); // Comparamos el "prosumidor de la oferta" con nuestro "actor prosumidor"
        assertEq(kwhOferta, 100);
        assertEq(precioOferta, 15);
        assertEq(activaOferta, true);
    }

   /**
     * @dev Prueba que un consumidor pueda comprar energía de una oferta.
     */
    function test_ComprarEnergia() public {
        // --- 1. ARRANGE (Preparar el escenario) ---
        
        // A. Publicar una oferta primero
        vm.prank(prosumidor); // Simulamos ser el prosumidor
        uint kwhOfertados = 100;
        uint precio = 15; // 15 wei por kWh
        mercado.publicarOferta(kwhOfertados, precio); // ID de esta oferta será 1

        // B. Calcular el costo de la compra
        uint kwhAComprar = 20;
        uint costoTotal = kwhAComprar * precio; // 20 * 15 = 300 wei

        // C. Darle fondos (Ether) a nuestro actor 'consumidor'
        vm.deal(consumidor, 1000); // Le damos 1000 wei al consumidor

        // ---- LA CORRECCIÓN ESTÁ AQUÍ ----
        // D. Guardamos los balances ANTES de la transacción
        uint balanceConsumidorAntes = consumidor.balance;  // 1000
        uint balanceProsumidorAntes = prosumidor.balance;  // Un número gigante

        // --- 2. ACT (Actuar) ---
        
        // Simulamos ser el CONSUMIDOR
        vm.prank(consumidor);
        // El consumidor llama a 'comprarEnergia' y adjunta el dinero (costoTotal)
        mercado.comprarEnergia{value: costoTotal}(1, kwhAComprar);

        // --- 3. ASSERT (Verificar) ---

        // A. Verificar que el dinero se movió
        
        // El consumidor debe tener su balance anterior MENOS el costo
        assertEq(consumidor.balance, balanceConsumidorAntes - costoTotal); // 1000 - 300 = 700
        
        // El prosumidor debe tener su balance anterior MÁS el costo
        assertEq(prosumidor.balance, balanceProsumidorAntes + costoTotal); // (Gigante + 300)

        // B. Verificar que la oferta se actualizó
        (,, uint kwhRestantes, , ) = mercado.ofertas(1); // Obtenemos solo el 3er valor (kwh)
        assertEq(kwhRestantes, kwhOfertados - kwhAComprar); // 100 - 20 = 80
    }
}