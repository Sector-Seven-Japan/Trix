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
    "function name() view returns (string)",
    "function symbol() view returns (string)",
    "function decimals() view returns (uint8)"
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

const PORT = 3000;
app.listen(PORT, () => {
    console.log(`Server running on http://localhost:${PORT}`);
});
