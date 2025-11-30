// src/constants.js

// 1. URL del Túnel RPC (Terminal 2)
export const RPC_URL = "https://b081b2c4f9b17d.lhr.life";

// 2. Dirección del Contrato (Terminal 3)
export const CONTRACT_ADDRESS = "0x5FbDB2315678afecb367f032d93F642f64180aa3";
// 3. El ABI (El mapa del contrato). 
// Copia TODO el contenido de tu archivo MercadoEnergetico.json aquí.
// Por brevedad, pongo un ejemplo resumido, pero tú debes pegar el real.
export const CONTRACT_ABI = [
    "function publicarOferta(uint _kwh, uint _precioPorKwh) public",
    "function comprarEnergia(uint _idOferta, uint _kwhAComprar) public payable",
    "function ofertas(uint) view returns (uint, address, uint, uint, bool)",
    "function contadorOfertas() view returns (uint)",
    "event OfertaPublicada(uint id, address prosumidor, uint kwh, uint precioPorKwh)",
    "event EnergiaComprada(uint idOferta, address consumidor, uint kwhComprados, uint costoTotal, uint pagoProsumidor, uint gridFee)"
];

// 4. Usuarios Simulados con Credenciales
export const USERS = [
    { 
        username: "admin0",
        password: "admin0",
        name: "Prosumidor A (Host)", 
        address: "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266", 
        privateKey: "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80" 
    }, 
    { 
        username: "admin1",
        password: "admin1",
        name: "Prosumidor B (Vecino 1)", 
        address: "0x70997970C51812dc3A010C7d01b50e0d17dc79C8", 
        privateKey: "0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d" 
    }, 
    { 
        username: "admin2",
        password: "admin2",
        name: "Prosumidor C (Vecino 2)", 
        address: "0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC", 
        privateKey: "0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a" 
    } 
];