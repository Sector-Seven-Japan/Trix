// プロバイダーの設定を最適化
const provider = new ethers.providers.JsonRpcProvider({
    url: process.env.INFURA_API_URL,
    timeout: 30000, // タイムアウトを30秒に設定
    allowGzip: true,
    headers: {
        Accept: "*/*",
        "Accept-Encoding": "gzip, deflate, br",
        "Cache-Control": "no-cache"
    }
});

// キャッシュを実装
const cache = new Map();
const CACHE_TTL = 60 * 1000; // 1分

// キャッシュ付きの残高取得関数
async function getCachedBalance(address) {
    const cacheKey = `balance:${address}`;
    const cached = cache.get(cacheKey);
    if (cached && Date.now() - cached.timestamp < CACHE_TTL) {
        return cached.value;
    }

    const usdtContract = getContract(usdtAddress, usdtAbi, defaultWallet);
    const balance = await usdtContract.balanceOf(address);
    const decimals = await usdtContract.decimals();
    const formattedBalance = ethers.utils.formatUnits(balance, decimals);

    cache.set(cacheKey, {
        value: formattedBalance,
        timestamp: Date.now()
    });

    return formattedBalance;
}

// 残高取得エンドポイントを修正
app.get("/balance/:address", async (req, res) => {
    try {
        const address = req.params.address;
        if (!ethers.utils.isAddress(address)) {
            return res.status(400).json({ error: "Invalid Ethereum address" });
        }
        const balance = await getCachedBalance(address);
        res.json({ balance });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
}); 