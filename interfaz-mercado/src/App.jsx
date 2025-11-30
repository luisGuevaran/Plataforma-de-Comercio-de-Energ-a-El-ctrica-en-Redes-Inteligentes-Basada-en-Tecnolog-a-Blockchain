import { useState, useEffect } from 'react';
import { ethers } from 'ethers';
import { RPC_URL, CONTRACT_ADDRESS, CONTRACT_ABI, USERS } from './constants';
import './App.css';

function App() {
  const [isLoggedIn, setIsLoggedIn] = useState(false);
  const [loginUser, setLoginUser] = useState("");
  const [loginPass, setLoginPass] = useState("");
  const [currentUser, setCurrentUser] = useState(null);

  const [provider, setProvider] = useState(null);
  const [contract, setContract] = useState(null);
  const [signer, setSigner] = useState(null);
  
  const [offers, setOffers] = useState([]);
  const [history, setHistory] = useState([]);
  
  // Estados del Medidor Personal
  const [myEthBalance, setMyEthBalance] = useState("0");
  const [myEnergyBought, setMyEnergyBought] = useState(0);
  
  const [kwhToSell, setKwhToSell] = useState("");
  const [priceToSell, setPriceToSell] = useState("");
  const [buyAmount, setBuyAmount] = useState("");

  // 1. Conexión Inicial
  useEffect(() => {
    const init = async () => {
      try {
        const newProvider = new ethers.JsonRpcProvider(RPC_URL);
        const newContract = new ethers.Contract(CONTRACT_ADDRESS, CONTRACT_ABI, newProvider);
        setProvider(newProvider);
        setContract(newContract);
      } catch (error) {
        console.error("Error de conexión:", error);
      }
    };
    init();
  }, []);

  // 2. Actualizar Medidor (Balance y Energía)
  useEffect(() => {
    const updateMeter = async () => {
      if (provider && currentUser && isLoggedIn) {
        // A. Obtener Saldo ETH Real
        const balance = await provider.getBalance(currentUser.address);
        setMyEthBalance(ethers.formatEther(balance));

        // B. Calcular Energía Acumulada (Sumando compras del historial)
        // Filtramos el historial donde el comprador soy YO
        const myPurchases = history.filter(h => h.consumidor.toLowerCase() === currentUser.address.toLowerCase());
        const totalKwh = myPurchases.reduce((acc, curr) => acc + Number(curr.kwh), 0);
        setMyEnergyBought(totalKwh);
      }
    };
    updateMeter();
  }, [history, currentUser, provider, isLoggedIn]); // Se actualiza si cambia el historial

  const handleLogin = (e) => {
    e.preventDefault();
    const foundUser = USERS.find(u => u.username === loginUser && u.password === loginPass);

    if (foundUser) {
      setCurrentUser(foundUser);
      setIsLoggedIn(true);
      if (provider) {
        const wallet = new ethers.Wallet(foundUser.privateKey, provider);
        setSigner(wallet);
        loadOffers(contract);
        loadHistory(contract, provider);
      }
    } else {
      alert("Credenciales inválidas.");
    }
  };

  const handleLogout = () => {
    setIsLoggedIn(false);
    setCurrentUser(null);
    setSigner(null);
    setLoginUser("");
    setLoginPass("");
  };

  const loadOffers = async (contractInstance) => {
    if (!contractInstance) return;
    try {
      const total = await contractInstance.contadorOfertas();
      let loadedOffers = [];
      for (let i = 1; i <= total; i++) {
        const o = await contractInstance.ofertas(i);
        if (o[4] === true) { 
          loadedOffers.push({
            id: i,
            prosumidor: o[1],
            kwh: o[2].toString(),
            precio: ethers.formatUnits(o[3], "wei"),
          });
        }
      }
      setOffers(loadedOffers);
    } catch (error) {
      console.error("Error recuperando órdenes:", error);
    }
  };

  const loadHistory = async (contractInstance) => {
    if (!contractInstance) return;
    const filter = contractInstance.filters.EnergiaComprada();
    const events = await contractInstance.queryFilter(filter, 0, "latest");
    
    const historyData = events.map(e => ({
      hash: e.transactionHash,
      offerId: e.args[0].toString(),
      consumidor: e.args[1],
      kwh: e.args[2].toString(),
      costoTotal: ethers.formatUnits(e.args[3], "wei"),
      pagoProsumidor: ethers.formatUnits(e.args[4], "wei"),
      pagoDSO: ethers.formatUnits(e.args[5], "wei")
    })).reverse();
    
    setHistory(historyData);
  };

  const handlePublish = async () => {
    if (!signer) return;
    try {
      const contractWithSigner = contract.connect(signer);
      const tx = await contractWithSigner.publicarOferta(kwhToSell, priceToSell, { gasLimit: 500000 });
      await tx.wait();
      alert("Orden registrada.");
      loadOffers(contract);
    } catch (error) {
      alert("Error: " + error.message);
    }
  };

  const handleBuy = async (offerId, pricePerKwh) => {
    if (!signer) return;
    try {
      const contractWithSigner = contract.connect(signer);
      const cost = BigInt(buyAmount) * BigInt(pricePerKwh);
      const tx = await contractWithSigner.comprarEnergia(offerId, buyAmount, { value: cost, gasLimit: 500000 });
      await tx.wait();
      alert("Compra exitosa.");
      loadOffers(contract);
      loadHistory(contract);
    } catch (error) {
      alert("Error: " + error.message);
    }
  };

  if (!isLoggedIn) {
    return (
      <div className="login-container">
        <div className="login-box">
          <div className="login-header">
            <h2>ACCESO SEGURO</h2>
            <p>Red Energética Inteligente</p>
          </div>
          <form onSubmit={handleLogin}>
            <div className="input-group">
              <label>Usuario</label>
              <input type="text" value={loginUser} onChange={(e) => setLoginUser(e.target.value)}/>
            </div>
            <div className="input-group">
              <label>Clave de Acceso</label>
              <input type="password" value={loginPass} onChange={(e) => setLoginPass(e.target.value)}/>
            </div>
            <button type="submit">CONECTAR NODO</button>
          </form>
        </div>
      </div>
    );
  }

  return (
    <div className="app-layout">
      {/* BARRA SUPERIOR */}
      <nav className="navbar">
        <div className="nav-brand">RED ENERGÉTICA INTELIGENTE P2P</div>
        <div className="nav-user">
          <div className="user-details-container">
            <div className="user-details">
              <span className="user-name">{currentUser.name}</span>
              <span className="user-role">Nodo Activo</span>
            </div>
            {/* Tooltip Usuario */}
            <div className="custom-tooltip user-tooltip">
              <p><strong>Usuario:</strong> {currentUser.username}</p>
              <p><strong>Dirección:</strong></p>
              <code className="full-address">{currentUser.address}</code>
            </div>
          </div>
          <button onClick={handleLogout} className="btn-logout">Salir</button>
        </div>
      </nav>

      <div className="main-content">
        
        {/* --- NUEVO: PANEL DE MEDIDOR INTELIGENTE --- */}
        <div className="meter-section">
          <div className="meter-card">
            <div className="meter-icon">⚡</div>
            <div className="meter-info">
              <h3>Energía Adquirida</h3>
              <p className="meter-value">{myEnergyBought} <span className="unit">kWh</span></p>
              <small>Acumulado Histórico</small>
            </div>
          </div>
          <div className="meter-card">
            <div className="meter-icon">💰</div>
            <div className="meter-info">
              <h3>Saldo Financiero</h3>
              <p className="meter-value">{parseFloat(myEthBalance).toFixed(4)} <span className="unit">ETH</span></p>
              <small>Disponible en Wallet</small>
            </div>
          </div>
        </div>

        <div className="dashboard-grid">
          {/* COLUMNA IZQUIERDA */}
          <div className="col-left">
            <div className="panel">
              <div className="panel-header"><h3>Generar Orden de Venta</h3></div>
              <div className="panel-body">
                <div className="form-row">
                  <div className="form-group">
                    <label>Capacidad (kWh)</label>
                    <input type="number" onChange={e => setKwhToSell(e.target.value)} />
                  </div>
                  <div className="form-group">
                    <label>Precio Unitario (Wei)</label>
                    <input type="number" onChange={e => setPriceToSell(e.target.value)} />
                  </div>
                </div>
                <button className="btn-primary full-width" onClick={handlePublish}>REGISTRAR OFERTA</button>
              </div>
            </div>

            <div className="panel">
              <div className="panel-header"><h3>Mercado Disponible</h3></div>
              <div className="panel-body scrollable-list">
                {offers.length === 0 ? <p className="no-data">Esperando ofertas de la red...</p> : offers.map((o) => (
                  <div key={o.id} className="order-item">
                    <div className="order-info">
                      <span className="order-id">ORD-{o.id}</span>
                      <span className="order-detail">{o.kwh} kWh @ {o.precio} Wei</span>
                      <span className="order-seller">Nodo: {o.prosumidor.slice(0,6)}...</span>
                    </div>
                    {o.prosumidor.toLowerCase() === currentUser.address.toLowerCase() ? (
                      <span className="badge-own">PROPIA</span>
                    ) : (
                      <div className="buy-action">
                        <input placeholder="Cant." type="number" onChange={e => setBuyAmount(e.target.value)} />
                        <button className="btn-secondary" onClick={() => handleBuy(o.id, o.precio)}>ADQUIRIR</button>
                      </div>
                    )}
                  </div>
                ))}
              </div>
            </div>
          </div>

          {/* COLUMNA DERECHA: REGISTROS CON TOOLTIP */}
          <div className="col-right">
            <div className="panel">
              <div className="panel-header"><h3>Libro Mayor Distribuido (Ledger)</h3></div>
              <div className="panel-body">
                <table className="data-table">
                  <thead>
                    <tr>
                      <th>Hash (ID)</th>
                      <th>Comprador</th>
                      <th>Vol.</th>
                      <th>Pago Total</th>
                    </tr>
                  </thead>
                  <tbody>
                    {history.map((h, i) => (
                      <tr key={i} className={h.consumidor.toLowerCase() === currentUser.address.toLowerCase() ? "my-transaction" : ""}>
                        
                        {/* CELDA CON TOOLTIP DE DETALLES */}
                        <td className="hash-cell">
                          <span className="hash-text">{h.hash.slice(0, 10)}...</span>
                          
                          {/* El Tooltip Oculto */}
                          <div className="table-tooltip">
                            <h4>Detalle de Transacción</h4>
                            <p><strong>Hash Completo:</strong> <br/><span className="mono-small">{h.hash}</span></p>
                            <hr/>
                            <p><strong>Oferta ID:</strong> {h.offerId}</p>
                            <p><strong>Comprador:</strong> {h.consumidor}</p>
                            <p><strong>Energía:</strong> {h.kwh} kWh</p>
                            <p><strong>Costo Total:</strong> {h.costoTotal} Wei</p>
                            <hr/>
                            <p><strong>Liquidación Vendedor:</strong> {h.pagoProsumidor} Wei</p>
                            <p><strong>Tarifa de Red (DSO):</strong> {h.pagoDSO} Wei</p>
                          </div>
                        </td>

                        <td>{h.consumidor.slice(0,6)}...</td>
                        <td>{h.kwh}</td>
                        <td>{h.costoTotal}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
          </div>

        </div>
      </div>
    </div>
  );
}

export default App;