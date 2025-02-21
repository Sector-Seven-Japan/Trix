require("dotenv").config();
const express = require("express");
const { ethers } = require("ethers");

const app = express();
app.use(express.json());

const provider = new ethers.providers.JsonRpcProvider(process.env.INFURA_API_URL);
const wallet = new ethers.Wallet(process.env.PRIVATE_KEY, provider);
const usdtAddress = process.env.USDT_CONTRACT_ADDRESS;
const usdtAbi = [
    "function balanceOf(address) view returns (uint256)",
    "function transfer(address to, uint256 amount) returns (bool)",
    "function transferFrom(address from, address to, uint256 amount) returns (bool)",
    "function approve(address spender, uint256 amount) returns (bool)",
    "function allowance(address owner, address spender) view returns (uint256)",
    "function mint(address to, uint256 amount)",
    "function name() view returns (string)",
    "function symbol() view returns (string)",
    "function decimals() view returns (uint8)",
    "function owner() view returns (address)",
    "function totalSupply() view returns (uint256)"
];
const usdtContract = new ethers.Contract(usdtAddress, usdtAbi, wallet);

// **1. USDT 残高を取得**
app.get("/balance/:address", async (req, res) => {
    try {
        const address = req.params.address;
        if (!ethers.utils.isAddress(address)) {
            return res.status(400).json({ error: "Invalid Ethereum address" });
        }
        const balance = await usdtContract.balanceOf(address);
        const decimals = await usdtContract.decimals();
        res.json({ balance: ethers.utils.formatUnits(balance, decimals) });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// **2. USDT 送金**
app.post("/transfer", async (req, res) => {
    try {
        const { to, amount } = req.body;
        const decimals = await usdtContract.decimals();
        const tx = await usdtContract.transfer(to, ethers.utils.parseUnits(amount, decimals));
        await tx.wait();
        res.json({ txHash: tx.hash });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// **3. USDT コントラクトのメタデータ取得**
app.get("/metadata", async (req, res) => {
    try {
        const name = await usdtContract.name();
        const symbol = await usdtContract.symbol();
        const decimals = await usdtContract.decimals();
        res.json({ name, symbol, decimals });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// **4. 承認 (approve)**
app.post("/approve", async (req, res) => {
    try {
        const { spender, amount } = req.body;
        const decimals = await usdtContract.decimals();
        const tx = await usdtContract.approve(spender, ethers.utils.parseUnits(amount, decimals));
        await tx.wait();
        res.json({ txHash: tx.hash });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// **5. 承認済みトークン残高 (allowance)**
app.get("/allowance/:owner/:spender", async (req, res) => {
    try {
        const { owner, spender } = req.params;
        const allowance = await usdtContract.allowance(owner, spender);
        const decimals = await usdtContract.decimals();
        res.json({ allowance: ethers.utils.formatUnits(allowance, decimals) });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// **6. トークンの発行 (mint)**
app.post("/mint", async (req, res) => {
    try {
        const { to, amount } = req.body;
        const decimals = await usdtContract.decimals();
        const tx = await usdtContract.mint(to, ethers.utils.parseUnits(amount, decimals));
        await tx.wait();
        res.json({ txHash: tx.hash });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// **7. transferFrom を実行**
app.post("/transferFrom", async (req, res) => {
    try {
        const { from, to, amount } = req.body;
        const decimals = await usdtContract.decimals();
        const tx = await usdtContract.transferFrom(from, to, ethers.utils.parseUnits(amount, decimals));
        await tx.wait();
        res.json({ txHash: tx.hash });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// **8. トークン所有者を取得**
app.get("/owner", async (req, res) => {
    try {
        const owner = await usdtContract.owner();
        res.json({ owner });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// **9. 発行済みトークンの総量を取得**
app.get("/totalSupply", async (req, res) => {
    try {
        const totalSupply = await usdtContract.totalSupply();
        const decimals = await usdtContract.decimals();
        res.json({ totalSupply: ethers.utils.formatUnits(totalSupply, decimals) });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// サーバー起動
const PORT = 3000;
app.listen(PORT, () => {
    console.log(`Server running on http://localhost:${PORT}`);
});
