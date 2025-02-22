require("dotenv").config();
const express = require("express");
const { ethers } = require("ethers");

const app = express();
app.use(express.json());

const provider = new ethers.providers.JsonRpcProvider(process.env.INFURA_API_URL);
const wallet = new ethers.Wallet(process.env.PRIVATE_KEY, provider);

const usdtAddress = process.env.USDT_CONTRACT_ADDRESS;
const gameCoinAddress = process.env.GAME_COIN_CONTRACT_ADDRESS;
const bcmAddress = process.env.BCM_CONTRACT_ADDRESS;

// **ERC20 (USDT) コントラクト ABI**
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

// **GameCoin コントラクト ABI**
const gameCoinAbi = [
    "function depositAndApproveUSDT(uint256 amount) external",
    "function withdrawUSDT(address to, uint256 amount) external",
    "function getContractUSDTBalance() external view returns (uint256)",
    "function getAllowance(address user) external view returns (uint256)",
    "function useGameCoin(uint256 amount) external",
    "function gameCoinBalance(address) external view returns (uint256)",
    "function owner() view returns (address)"
];
const gameCoinContract = new ethers.Contract(gameCoinAddress, gameCoinAbi, wallet);

// **ERC721 (BCM) コントラクト ABI**
const bcmAbi = [
    "function approve(address to, uint256 tokenId) public",
    "function mintNFTWithGroup(address recipient, string memory tokenURI, string memory group) public returns (uint256)",
    "function safeTransferFrom(address from, address to, uint256 tokenId) public",
    "function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public",
    "function setApprovalForAll(address operator, bool approved) public",
    "function transferFrom(address from, address to, uint256 tokenId) public",
    "function balanceOf(address owner) public view returns (uint256)",
    "function getApproved(uint256 tokenId) public view returns (address)",
    "function getTokenGroup(uint256 tokenId) public view returns (string memory)",
    "function isApprovedForAll(address owner, address operator) public view returns (bool)",
    "function name() public view returns (string memory)",
    "function ownerOf(uint256 tokenId) public view returns (address)",
    "function supportsInterface(bytes4 interfaceId) public view returns (bool)",
    "function symbol() public view returns (string memory)",
    "function tokenURI(uint256 tokenId) public view returns (string memory)",
    "event Transfer(address indexed from, address indexed to, uint256 indexed tokenId)"
];
const bcmContract = new ethers.Contract(bcmAddress, bcmAbi, wallet);


// **🟢 ERC20 (USDT) 関連**
// **1. USDT 残高を取得**
app.get("/balance/:address", async (req, res) => {
    try {
        const address = req.params.address;
        if (!ethers.utils.isAddress(address)) {
            return res.status(400).json({ error: "Invalid Ethereum address" });
        }
        const balance = await usdtContract.balanceOf(address);
        const decimals = await usdtContract.decimals();
        const formattedBalance = ethers.utils.formatUnits(balance, decimals);
        res.json({ balance: formattedBalance });
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


// **🟡 GameCoinContract 関連**
// **1. USDT のデポジット & 承認**
app.post("/gamecoin/deposit", async (req, res) => {
    try {
        const { amount } = req.body;
        const decimals = await usdtContract.decimals();
        const parsedAmount = ethers.utils.parseUnits(amount, decimals);
        const receipt = await sendTransaction(
            gameCoinContract,
            'depositAndApproveUSDT',
            [parsedAmount]
        );
        res.json({ txHash: receipt.transactionHash });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// **2. USDT の引き出し（オーナーのみ）**
app.post("/gamecoin/withdraw", async (req, res) => {
    try {
        const { to, amount } = req.body;
        const owner = await gameCoinContract.owner();
        if (wallet.address.toLowerCase() !== owner.toLowerCase()) {
            return res.status(403).json({ error: "Only the owner can withdraw" });
        }

        const decimals = await gameCoinContract.decimals();
        const tx = await gameCoinContract.withdrawUSDT(to, ethers.utils.parseUnits(amount, decimals));
        await tx.wait();
        res.json({ txHash: tx.hash });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// **3. コントラクトの USDT 残高取得**
app.get("/gamecoin/usdtbalance", async (req, res) => {
    try {
        const balance = await gameCoinContract.getContractUSDTBalance();
        res.json({ balance: ethers.utils.formatUnits(balance, 18) });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// **4. USDT 承認済み残高取得**
app.get("/gamecoin/allowance/:user", async (req, res) => {
    try {
        const { user } = req.params;
        const allowance = await gameCoinContract.getAllowance(user);
        res.json({ allowance: ethers.utils.formatUnits(allowance, 18) });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// **5. GameCoin の使用**
app.post("/gamecoin/use", async (req, res) => {
    try {
        const { amount } = req.body;
        const tx = await gameCoinContract.useGameCoin(ethers.utils.parseUnits(amount, 18));
        await tx.wait();
        res.json({ txHash: tx.hash });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// **6. GameCoin の残高取得**
app.get("/gamecoin/balance/:user", async (req, res) => {
    try {
        const { user } = req.params;
        const balance = await gameCoinContract.gameCoinBalance(user);
        res.json({ balance: ethers.utils.formatUnits(balance, 18) });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});


// **🔵 ERC721 (BCM) 関連**
// **1. NFT をミント**
app.post("/bcm/mint", async (req, res) => {
    try {
        const { recipient, tokenURI, group } = req.body;
        const tx = await bcmContract.mintNFTWithGroup(recipient, tokenURI, group);
        const receipt = await tx.wait();
        
        // Transferイベントを直接取得
        const transferEvent = receipt.events.find(event => {
            return event && event.event === 'Transfer';
        });

        if (!transferEvent || !transferEvent.args) {
            throw new Error("Transfer event not found in transaction");
        }

        // tokenIdをイベントから取得
        const tokenId = transferEvent.args.tokenId.toString();
        
        // グループ情報を取得して確認
        const groupInfo = await bcmContract.getTokenGroup(tokenId);
        
        res.json({ 
            message: "NFT Minted",
            tokenId,
            txHash: tx.hash,
            recipient,
            group,
            confirmedGroup: groupInfo
        });
    } catch (error) {
        console.error("Mint error:", error);
        res.status(500).json({ 
            error: error.message,
            details: "Failed to mint NFT"
        });
    }
});

// **2. NFT を転送**
app.post("/bcm/transfer", async (req, res) => {
    try {
        const { from, to, tokenId } = req.body;
        const tx = await bcmContract.transferFrom(from, to, tokenId);
        await tx.wait();
        res.json({ message: "NFT Transferred", txHash: tx.hash });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// **3. NFT を安全に転送 (safeTransferFrom)**
app.post("/bcm/safeTransfer", async (req, res) => {
    try {
        const { from, to, tokenId } = req.body;
        const tx = await bcmContract.safeTransferFrom(from, to, tokenId);
        await tx.wait();
        res.json({ message: "NFT Safely Transferred", txHash: tx.hash });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// **4. NFT の承認**
app.post("/bcm/approve", async (req, res) => {
    try {
        const { to, tokenId } = req.body;
        const tx = await bcmContract.approve(to, tokenId);
        await tx.wait();
        res.json({ message: "NFT Approved", txHash: tx.hash });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// **5. 全 NFT を承認**
app.post("/bcm/setApprovalForAll", async (req, res) => {
    try {
        const { operator, approved } = req.body;
        const tx = await bcmContract.setApprovalForAll(operator, approved);
        await tx.wait();
        res.json({ message: "Approval for all set", txHash: tx.hash });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// **6. NFT の所有者を取得**
app.get("/bcm/owner/:tokenId", async (req, res) => {
    try {
        const owner = await bcmContract.ownerOf(req.params.tokenId);
        res.json({ tokenId: req.params.tokenId, owner });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// **7. ウォレットの NFT 保有数を取得**
app.get("/bcm/balance/:address", async (req, res) => {
    try {
        const balance = await bcmContract.balanceOf(req.params.address);
        res.json({ address: req.params.address, balance: balance.toString() });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// **8. NFT の承認アドレスを取得**
app.get("/bcm/getApproved/:tokenId", async (req, res) => {
    try {
        const approved = await bcmContract.getApproved(req.params.tokenId);
        res.json({ tokenId: req.params.tokenId, approved });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// **9. コントラクトの基本情報を取得**
app.get("/bcm/metadata", async (req, res) => {
    try {
        const name = await bcmContract.name();
        const symbol = await bcmContract.symbol();
        res.json({ name, symbol });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// トランザクション送信の共通関数を更新
async function sendTransaction(contract, method, params) {
    try {
        const tx = await contract[method](...params);
        const receipt = await tx.wait();
        return receipt;
    } catch (error) {
        console.error(`Transaction error in ${method}:`, error);
        throw error;
    }
}

// **サーバー起動**
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`Server running on http://localhost:${PORT}`);
});
