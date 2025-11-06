import json
from web3 import Web3
from web3.middleware import ExtraDataToPOAMiddleware # Para Anvil
# --- 1. CONFIGURACIÓN ---
anvil_url = "http://127.0.0.1:8545"
web3 = Web3(Web3.HTTPProvider(anvil_url))
web3.middleware_onion.inject(ExtraDataToPOAMiddleware, layer=0) # Necesario para Anvil
print(f"Conectado a Anvil: {web3.is_connected()}")
print(f"Block actual: {web3.eth.block_number}")


# --- 2. DATOS DEL CONTRATO (IMPORTANTE) ---

# PEGA AQUÍ LA DIRECCIÓN DE TU CONTRATO (de la Terminal 2)
DIRECCION_CONTRATO = "0x5FbDB2315678afecb367f032d93F642f64180aa3"

# El ABI (Interfaz) le dice a Python qué funciones tiene tu contrato.
# Lo encuentras en: out/MercadoEnergetico.sol/MercadoEnergetico.json
f = open('out/MercadoEnergetico.sol/MercadoEnergetico.json')
abi = json.load(f)['abi']
f.close()

# Cargar el contrato
contrato = web3.eth.contract(address="0x5FbDB2315678afecb367f032d93F642f64180aa3", abi=abi)


# --- 3. DEFINIR ACTORES (De las cuentas de Anvil) ---

# Anvil te dio 10 cuentas. Usemos las dos primeras.
# (Estas llaves privadas son PÚBLICAS y SOLO para pruebas locales)
prosumidor_address = "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266" # Cuenta #0 de Anvil
prosumidor_key = "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"

consumidor_address = "0x70997970C51812dc3A010C7d01b50e0d17dc79C8" # Cuenta #1 de Anvil
consumidor_key = "0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d"


print("\n--- INICIO DE LA SIMULACION ---")

# --- 4. ACTOR 1 (PROSUMIDOR) PUBLICA UNA OFERTA ---

print(f"\n[PROSUMIDOR] Publicando oferta...")

# 1. Crear la transacción
tx = contrato.functions.publicarOferta(
    100, # _kwh
    15   # _precioPorKwh
).build_transaction({
    'from': prosumidor_address,
    'nonce': web3.eth.get_transaction_count(prosumidor_address)
})

# 2. Firmar la transacción
tx_firmada = web3.eth.account.sign_transaction(tx, private_key=prosumidor_key)

# 3. Enviar la transacción
tx_hash = web3.eth.send_raw_transaction(tx_firmada.raw_transaction)
recibo = web3.eth.wait_for_transaction_receipt(tx_hash)

print(f"[PROSUMIDOR] ¡Oferta publicada! ID de oferta: 1 (lo asumimos)")


# --- 5. ACTOR 2 (CONSUMIDOR) COMPRA LA ENERGÍA ---

print(f"\n[CONSUMIDOR] Comprando 20 kWh de la oferta 1...")

id_oferta = 1
kwh_a_comprar = 20
precio_por_kwh = 15
costo_total = kwh_a_comprar * precio_por_kwh # 300 wei

# 1. Crear la transacción
tx_compra = contrato.functions.comprarEnergia(
    id_oferta,
    kwh_a_comprar
).build_transaction({
    'from': consumidor_address,
    'value': costo_total, # ¡Adjuntamos el pago!
    'nonce': web3.eth.get_transaction_count(consumidor_address)
})

# 2. Firmar
tx_compra_firmada = web3.eth.account.sign_transaction(tx_compra, private_key=consumidor_key)

# 3. Enviar
tx_hash_compra = web3.eth.send_raw_transaction(tx_compra_firmada.raw_transaction)
recibo_compra = web3.eth.wait_for_transaction_receipt(tx_hash_compra)

print(f"[CONSUMIDOR] ¡Energía comprada exitosamente!")

# --- 6. VERIFICACIÓN FINAL (Leyendo datos del contrato) ---

print(f"\n--- ESTADO FINAL DEL MERCADO ---")

# Llamar a una función 'view' (de solo lectura) no cuesta gas
# (id, prosumidor, kwh, precio, activa)
datos_oferta = contrato.functions.ofertas(1).call()

print(f"Datos de la Oferta 1: {datos_oferta}")
print(f"KWh restantes: {datos_oferta[2]}") # Debería ser 80

print("\n--- FIN DE LA SIMULACION ---")