import json
from web3 import Web3
from web3.middleware import ExtraDataToPOAMiddleware

# --- 1. CONFIGURACIÓN ---
anvil_url = "http://127.0.0.1:8545"
web3 = Web3(Web3.HTTPProvider(anvil_url))
web3.middleware_onion.inject(ExtraDataToPOAMiddleware, layer=0)

if not web3.is_connected():
    print("Error: No se pudo conectar con Anvil.")
    exit()

print("¡Conexión exitosa con Anvil!")

# --- 2. DATOS DEL CONTRATO (IMPORTANTE) ---

# PEGA AQUÍ LA DIRECCIÓN DE TU CONTRATO
DIRECCION_CONTRATO = "0x5FbDB2315678afecb367f032d93F642f64180aa3"

try:
    f = open('out/MercadoEnergetico.sol/MercadoEnergetico.json')
    abi = json.load(f)['abi']
    f.close()
except FileNotFoundError:
    print("Error: No se encontró el archivo ABI. ¿Compilaste tu contrato?")
    print("Ejecuta 'forge build' e inténtalo de nuevo.")
    exit()

# Cargar el contrato
contrato = web3.eth.contract(address=DIRECCION_CONTRATO, abi=abi)

# --- 3. DEFINIR ACTORES (Tus identidades) ---
# Usaremos las dos primeras cuentas de Anvil como tus "billeteras"
try:
    prosumidor_address = web3.eth.accounts[0] # Cuenta #0 de Anvil
    prosumidor_key = "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"

    consumidor_address = web3.eth.accounts[1] # Cuenta #1 de Anvil
    consumidor_key = "0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d"
except IndexError:
    print("Error: Anvil no devolvió cuentas. ¿Está corriendo Anvil?")
    exit()

print(f"Actuando como:\n"
      f"  Prosumidor: {prosumidor_address}\n"
      f"  Consumidor: {consumidor_address}\n")

# --- 4. FUNCIONES DE INTERACCIÓN ---

def publicar_oferta_interactiva():
    try:
        kwh = int(input("  ¿Cuántos kWh quieres vender? > "))
        precio = int(input("  ¿A qué precio (en wei) por kWh? > "))
    except ValueError:
        print("Error: Entrada inválida. Deben ser números.")
        return

    print(f"\n[PROSUMIDOR] Publicando oferta de {kwh} kWh a {precio} wei/kWh...")
    try:
        tx = contrato.functions.publicarOferta(kwh, precio).build_transaction({
            'from': prosumidor_address,
            'nonce': web3.eth.get_transaction_count(prosumidor_address)
        })
        tx_firmada = web3.eth.account.sign_transaction(tx, private_key=prosumidor_key)
        tx_hash = web3.eth.send_raw_transaction(tx_firmada.raw_transaction)
        recibo = web3.eth.wait_for_transaction_receipt(tx_hash)
        
        # Leer el ID de la oferta desde el evento (¡más robusto!)
        logs = contrato.events.OfertaPublicada().process_receipt(recibo)
        id_oferta = logs[0]['args']['id']
        print(f"¡Éxito! Oferta publicada con ID: {id_oferta}")

    except Exception as e:
        print(f"Error al publicar oferta: {e}")

def comprar_energia_interactiva():
    try:
        id_oferta = int(input("  ¿Qué ID de oferta quieres comprar? > "))
        kwh_a_comprar = int(input("  ¿Cuántos kWh quieres comprar? > "))
    except ValueError:
        print("Error: Entrada inválida. Deben ser números.")
        return

    # 1. Verificar el precio de la oferta ANTES de comprar
    try:
        (id, pro, kwh_disp, precio, activa) = contrato.functions.ofertas(id_oferta).call()
        if not activa:
            print("Error: Esta oferta ya no está activa.")
            return
        if kwh_a_comprar > kwh_disp:
            print(f"Error: No puedes comprar {kwh_a_comprar} kWh, solo hay {kwh_disp} disponibles.")
            return
    except Exception as e:
        print(f"Error: No se pudo encontrar la oferta {id_oferta}. ¿Existe?")
        return
    
    costo_total = kwh_a_comprar * precio
    print(f"\n[CONSUMIDOR] Comprando {kwh_a_comprar} kWh de la oferta {id_oferta}...")
    print(f"  Costo total calculado: {costo_total} wei")

    try:
        tx = contrato.functions.comprarEnergia(id_oferta, kwh_a_comprar).build_transaction({
            'from': consumidor_address,
            'value': costo_total, # Adjuntamos el pago
            'nonce': web3.eth.get_transaction_count(consumidor_address)
        })
        tx_firmada = web3.eth.account.sign_transaction(tx, private_key=consumidor_key)
        tx_hash = web3.eth.send_raw_transaction(tx_firmada.raw_transaction)
        recibo = web3.eth.wait_for_transaction_receipt(tx_hash)
        print("¡Éxito! Energía comprada.")

    except Exception as e:
        print(f"Error al comprar energía: {e}")

def ver_estado_oferta():
    try:
        id_oferta = int(input("  ¿Qué ID de oferta quieres ver? > "))
    except ValueError:
        print("Error: Entrada inválida. Debe ser un número.")
        return

    print(f"\nBuscando estado de la Oferta {id_oferta}...")
    try:
        # (id, prosumidor, kwh, precio, activa)
        datos_oferta = contrato.functions.ofertas(id_oferta).call()
        print("  --- DATOS DE LA OFERTA ---")
        print(f"  ID: {datos_oferta[0]}")
        print(f"  Prosumidor: {datos_oferta[1]}")
        print(f"  kWh restantes: {datos_oferta[2]}")
        print(f"  Precio (wei/kWh): {datos_oferta[3]}")
        print(f"  Activa: {datos_oferta[4]}")
        print("  -------------------------")
    except Exception as e:
        print(f"Error: No se pudo leer la oferta {id_oferta}. ¿Estás seguro que existe?")

# --- 5. MENÚ PRINCIPAL ---

def menu_principal():
    while True:
        print("\n--- MERCADO ENERGÉTICO INTERACTIVO ---")
        print("¿Qué quieres hacer?")
        print("  [1] Publicar Oferta (Actuar como Prosumidor)")
        print("  [2] Comprar Energía (Actuar como Consumidor)")
        print("  [3] Ver estado de una Oferta")
        print("  [S] Salir")
        
        opcion = input("> ").strip().lower()

        if opcion == '1':
            publicar_oferta_interactiva()
        elif opcion == '2':
            comprar_energia_interactiva()
        elif opcion == '3':
            ver_estado_oferta()
        elif opcion == 's':
            print("Saliendo. ¡Adiós!")
            break
        else:
            print("Opción no válida. Inténtalo de nuevo.")

# --- INICIAR LA APLICACIÓN ---
if __name__ == "__main__":
    menu_principal()