// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/**
 * @title MercadoEnergetico
 * @dev Este contrato gestiona la compra-venta de energía entre prosumidores y consumidores.
 */
contract MercadoEnergetico {

    // -----------
    // Estado
    // -----------

    // Estructura para definir una oferta de energía
    struct Oferta {
        uint id;
        address prosumidor; // Quién la vende
        uint kwh;          // Cantidad de energía
        uint precioPorKwh; // Precio
        bool activa;       // Si todavía está disponible
    }

    // Un contador para darle IDs únicos a las ofertas
    uint public contadorOfertas;

    // Un "mapa" para guardar todas las ofertas por su ID
    // mapping(ID_Oferta => Datos_De_La_Oferta)
    mapping(uint => Oferta) public ofertas;

    // -----------
    // Eventos
    // -----------

    // Se emiten cuando algo importante pasa. Útil para tu simulación.
    event OfertaPublicada(uint id, address prosumidor, uint kwh, uint precioPorKwh);
    event EnergiaComprada(uint idOferta, address consumidor, uint kwhComprados);

    // -----------
    // Funciones
    // -----------

    /**
     * @dev Permite a un prosumidor publicar una nueva oferta de energía.
     */
    function publicarOferta(uint _kwh, uint _precioPorKwh) public {
        // Incrementa el contador para el nuevo ID
        contadorOfertas++;
        
        // Crea la nueva oferta en memoria
        Oferta memory nuevaOferta = Oferta({
            id: contadorOfertas,
            prosumidor: msg.sender, // msg.sender es la wallet que llama la función
            kwh: _kwh,
            precioPorKwh: _precioPorKwh,
            activa: true
        });

        // Guarda la oferta en el "mapa" (storage)
        ofertas[contadorOfertas] = nuevaOferta;

        // Emite el evento para avisar
        emit OfertaPublicada(contadorOfertas, msg.sender, _kwh, _precioPorKwh);
    }

    /**
     * @dev Permite a un consumidor comprar energía de una oferta activa.
     * La función es 'payable', lo que significa que puede RECIBIR Ether.
     */
    function comprarEnergia(uint _idOferta, uint _kwhAComprar) public payable {
        
        // 1. Obtener la oferta del storage (almacenamiento)
        // Usamos 'storage' para poder modificarla.
        Oferta storage oferta = ofertas[_idOferta];

        // 2. --- Verificaciones (Validaciones) ---
        
        // Verificar que la oferta existe y está activa
        require(oferta.activa == true, "Mercado: La oferta no esta activa");

        // Verificar que la oferta tiene suficiente energía
        require(_kwhAComprar <= oferta.kwh, "Mercado: No hay suficientes kWh en la oferta");

        // 3. --- Cálculo de Pago ---
        uint costoTotal = _kwhAComprar * oferta.precioPorKwh;

        // Verificar que el comprador (msg.sender) envió suficiente Ether
        // msg.value es la cantidad de Ether (en 'wei') enviada con la transacción
        require(msg.value >= costoTotal, "Mercado: Fondos insuficientes para la compra");

        // 4. --- Ejecución del Estado (Actualizaciones) ---

        // Restar la energía comprada de la oferta
        oferta.kwh = oferta.kwh - _kwhAComprar;

        // Si la oferta se agota, desactivarla
        if (oferta.kwh == 0) {
            oferta.activa = false;
        }

        // 5. --- Transferencia de Fondos ---
        // Enviar el Ether al prosumidor (dueño de la oferta)
        // (bool success, ) = oferta.prosumidor.call{value: costoTotal}("");
        // require(success, "Mercado: Transferencia fallida");
        
        // Forma más simple (y ahora recomendada) de transferir:
        payable(oferta.prosumidor).transfer(costoTotal);

        // Devolver el cambio si el comprador pagó de más
        if (msg.value > costoTotal) {
            payable(msg.sender).transfer(msg.value - costoTotal);
        }

        // 6. --- Evento ---
        // Emitir el evento para que el mundo exterior sepa de la compra
        emit EnergiaComprada(_idOferta, msg.sender, _kwhAComprar);
    }
}