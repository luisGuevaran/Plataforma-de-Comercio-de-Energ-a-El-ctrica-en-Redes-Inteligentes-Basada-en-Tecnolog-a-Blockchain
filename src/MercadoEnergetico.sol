// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/**
 * @title MercadoEnergetico
 * @dev Gestiona la compra-venta de energía y paga una tarifa de red al DSO.
 */
contract MercadoEnergetico {

    // -----------
    // Estado
    // -----------

    struct Oferta {
        uint id;
        address prosumidor; // Quién la vende
        uint kwh;          // Cantidad de energía
        uint precioPorKwh; // Precio
        bool activa;       // Si todavía está disponible
    }

    uint public contadorOfertas;
    mapping(uint => Oferta) public ofertas;

    address public immutable dsoAddress; // Dirección del Operador del Sistema (DSO)
    uint public immutable gridFeePercentage; // Porcentaje de la tarifa (ej: 3 para 3%)

    // -----------
    // Eventos
    // -----------

    event OfertaPublicada(uint id, address prosumidor, uint kwh, uint precioPorKwh);
    
    // --- (((( ¡EVENTO ACTUALIZADO! )))) ---
    // Ahora registraremos todos los detalles financieros de la transacción
    event EnergiaComprada(
        uint idOferta, 
        address consumidor, 
        uint kwhComprados,
        uint costoTotal,      // Cuánto GASTÓ el consumidor
        uint pagoProsumidor,  // Cuánto GANÓ el prosumidor
        uint gridFee          // Cuánto GANÓ el DSO
    );


    // -----------
    // Constructor
    // -----------

    /**
     * @dev Se ejecuta UNA SOLA VEZ al desplegar el contrato.
     * Define al DSO y la tarifa de red.
     */
    constructor(address _dsoAddress, uint _feePercentage) {
        require(_dsoAddress != address(0), "DSO no puede ser la direccion cero");
        require(_feePercentage <= 100, "La tarifa no puede ser > 100%"); // Prevenir errores
        dsoAddress = _dsoAddress;
        gridFeePercentage = _feePercentage;
    }

    // -----------
    // Funciones
    // -----------

    /**
     * @dev Permite a un prosumidor publicar una nueva oferta de energía.
     * (Esta función no cambia)
     */
    function publicarOferta(uint _kwh, uint _precioPorKwh) public {
        contadorOfertas++;
        
        Oferta memory nuevaOferta = Oferta({
            id: contadorOfertas,
            prosumidor: msg.sender, // msg.sender es la wallet que llama la función
            kwh: _kwh,
            precioPorKwh: _precioPorKwh,
            activa: true
        });

        ofertas[contadorOfertas] = nuevaOferta;
        emit OfertaPublicada(contadorOfertas, msg.sender, _kwh, _precioPorKwh);
    }

    /**
     * @dev Permite a un consumidor comprar energía de una oferta activa.
     * --- ¡LÓGICA ACTUALIZADA CON TARIFA DE RED! ---
     */
    function comprarEnergia(uint _idOferta, uint _kwhAComprar) public payable {
        
        // 1. Obtener la oferta del storage
        Oferta storage oferta = ofertas[_idOferta];

        // 2. --- Verificaciones (Validaciones) ---
        require(oferta.activa == true, "Mercado: La oferta no esta activa");
        require(_kwhAComprar <= oferta.kwh, "Mercado: No hay suficientes kWh en la oferta");

        // 3. --- Cálculo de Costo Total ---
        uint costoTotal = _kwhAComprar * oferta.precioPorKwh;
        require(msg.value >= costoTotal, "Mercado: Fondos insuficientes para la compra");

        // 4. --- LÓGICA DE TARIFA DE RED (DSO) ---
        // Calcular la tarifa para el DSO (ej. 3% del costoTotal)
        uint gridFee = (costoTotal * gridFeePercentage) / 100;
        
        // Calcular el pago neto para el Prosumidor
        uint pagoProsumidor = costoTotal - gridFee;

        // 5. --- Ejecución del Estado (Actualizaciones) ---
        oferta.kwh = oferta.kwh - _kwhAComprar;
        if (oferta.kwh == 0) {
            oferta.activa = false;
        }

        // 6. --- Transferencia de Fondos (Dividida) ---
        
        (bool dsoSuccess, ) = payable(dsoAddress).call{value: gridFee}("");
        require(dsoSuccess, "Transferencia al DSO fallida");
        
        (bool prosumidorSuccess, ) = payable(oferta.prosumidor).call{value: pagoProsumidor}("");
        require(prosumidorSuccess, "Transferencia al Prosumidor fallida");

        // 7. --- Devolver el cambio si el comprador pagó de más ---
        if (msg.value > costoTotal) {
            (bool refundSuccess, ) = payable(msg.sender).call{value: msg.value - costoTotal}("");
            require(refundSuccess, "Devolucion de cambio fallida");
        }

        // 8. --- (((( ¡EMIT ACTUALIZADO! )))) ---
        // Emitir el evento con TODOS los detalles financieros
        emit EnergiaComprada(
            _idOferta, 
            msg.sender, 
            _kwhAComprar, 
            costoTotal, 
            pagoProsumidor, 
            gridFee
        );
    }
}