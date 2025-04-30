```markdown:README.md
# NFT Marketplace API Documentation

## Setup
```bash
npm install
cp .env.example .env
# Edit .env with your configuration
npm start
```

## Authentication

すべてのAPIエンドポイントで、独自の秘密鍵を使用できます。
秘密鍵はリクエストヘッダーに含めて送信します：

```bash
-H "x-private-key: YOUR_PRIVATE_KEY"
```

例：
```bash
# USDTの送金（独自の秘密鍵を使用）
curl -X POST http://localhost:3000/transfer \
     -H "Content-Type: application/json" \
     -H "x-private-key: 557b5ef7d449367add5511d740a04ead66f0acd83caa57092c13a75fe8757951" \
     -d '{"to": "0x40deA50302F41b7B695135b588B1ce2b5834Ccd3", "amount": "1.0"}'

# NFTのミント（独自の秘密鍵を使用）
curl -X POST http://localhost:3000/bcm/mint \
     -H "Content-Type: application/json" \
     -H "x-private-key: 557b5ef7d449367add5511d740a04ead66f0acd83caa57092c13a75fe8757951" \
     -d '{"recipient": "0x04B236D5CC6fA765C0d209a3c8Faf1d368C6434e", "tokenURI": "https://example.com/metadata.json", "group": "1"}'
```

注意：
- 秘密鍵を指定しない場合は、デフォルトの秘密鍵（.envファイルのPRIVATE_KEY）が使用されます
- 秘密鍵は`0x`プレフィックスの有無どちらでも受け付けます
- 本番環境では、HTTPSの使用を強く推奨します

## API Endpoints

### USDT Operations

#### Get Balance
```bash
curl "http://localhost:3000/balance/0x04B236D5CC6fA765C0d209a3c8Faf1d368C6434e"
> {"balance":"1000177.0"}
```

#### Transfer USDT
```bash
curl -X POST http://localhost:3000/transfer \
     -H "Content-Type: application/json" \
     -d '{"to": "0x40deA50302F41b7B695135b588B1ce2b5834Ccd3", "amount": "1.0"}'
> {"txHash":"0x..."}
```

#### Get Metadata
```bash
curl "http://localhost:3000/metadata"
> {"name":"Test USDT","symbol":"USDT","decimals":18}
```

#### Approve USDT
```bash
curl -X POST http://localhost:3000/approve \
     -H "Content-Type: application/json" \
     -d '{"spender": "0x359394D70Ca0565C9F5e85D9182ae62D4bcfE745", "amount": "5.0"}'
> {"txHash":"0x..."}
```

#### Check Allowance
```bash
curl "http://localhost:3000/allowance/0x04B236D5CC6fA765C0d209a3c8Faf1d368C6434e/0x359394D70Ca0565C9F5e85D9182ae62D4bcfE745"
> {"allowance":"5.0"}
```

#### Get Owner
```bash
curl "http://localhost:3000/owner"
> {"owner":"0x04B236D5CC6fA765C0d209a3c8Faf1d368C6434e"}
```

#### Get Total Supply
```bash
curl "http://localhost:3000/totalSupply"
> {"totalSupply":"1001340.0"}
```

### GameCoin Operations

#### Deposit USDT
```bash
curl -X POST http://localhost:3000/gamecoin/deposit \
     -H "Content-Type: application/json" \
     -d '{"amount": "1.0"}'
> {"txHash":"0x..."}
```

#### Get USDT Balance
```bash
curl "http://localhost:3000/gamecoin/usdtbalance"
> {"balance":"2.0"}
```

#### Use GameCoin
```bash
curl -X POST http://localhost:3000/gamecoin/use \
     -H "Content-Type: application/json" \
     -d '{"amount": "0.5"}'
> {"txHash":"0x..."}
```

#### Get GameCoin Balance
```bash
curl "http://localhost:3000/gamecoin/balance/0x04B236D5CC6fA765C0d209a3c8Faf1d368C6434e"
> {"balance":"1.5"}
```

#### Withdraw USDT
```bash
curl -X POST http://localhost:3000/gamecoin/withdraw \
     -H "Content-Type: application/json" \
     -d '{"to": "0x04B236D5CC6fA765C0d209a3c8Faf1d368C6434e", "amount": "0.1"}'
> {"txHash":"0x..."}
```

### BCM (NFT) Operations

#### Mint NFT
```bash
curl -X POST http://localhost:3000/bcm/mint \
     -H "Content-Type: application/json" \
     -d '{"recipient": "0x04B236D5CC6fA765C0d209a3c8Faf1d368C6434e", "tokenURI": "https://example.com/metadata.json", "group": "1"}'
> {"message":"NFT Minted","tokenId":"20","txHash":"0x..."}
```

#### Approve NFT
```bash
curl -X POST http://localhost:3000/bcm/approve \
     -H "Content-Type: application/json" \
     -d '{"to": "0x1B8fC7DF8d0D97A25258a851dF95BAC20742C84c", "tokenId": "20"}'
> {"message":"NFT Approved","txHash":"0x..."}
```

#### Transfer NFT
```bash
curl -X POST http://localhost:3000/bcm/transfer \
     -H "Content-Type: application/json" \
     -d '{"from": "0x04B236D5CC6fA765C0d209a3c8Faf1d368C6434e", "to": "0x40deA50302F41b7B695135b588B1ce2b5834Ccd3", "tokenId": "20"}'
> {"message":"NFT Transferred","txHash":"0x..."}
```

#### Get NFT Owner
```bash
curl "http://localhost:3000/bcm/owner/20"
> {"tokenId":"20","owner":"0x..."}
```

#### Get NFT Balance
```bash
curl "http://localhost:3000/bcm/balance/0x04B236D5CC6fA765C0d209a3c8Faf1d368C6434e"
> {"address":"0x...","balance":"12"}
```

### Marketplace Operations

#### List NFT
```bash
curl -X POST http://localhost:3000/marketplace/list \
     -H "Content-Type: application/json" \
     -d '{"nftContract": "0x53B5F1de7f658aC9D466fDfF875d7353A0399bB5", "tokenId": "20", "price": "1.0", "group": "1"}'
> {"message":"NFT Listed","txHash":"0x..."}
```

#### Place Group Bid
```bash
curl -X POST http://localhost:3000/marketplace/bid \
     -H "Content-Type: application/json" \
     -d '{"group": "1", "price": "1.0"}'
> {"message":"Group Bid Placed","txHash":"0x..."}
```

#### Cancel Listing
```bash
curl -X POST http://localhost:3000/marketplace/cancel \
     -H "Content-Type: application/json" \
     -d '{"nftContract": "0x53B5F1de7f658aC9D466fDfF875d7353A0399bB5", "tokenId": "20"}'
> {"message":"Listing Cancelled","txHash":"0x..."}
```

#### Buy NFT
```bash
curl -X POST http://localhost:3000/marketplace/buy \
     -H "Content-Type: application/json" \
     -d '{"nftContract": "0x53B5F1de7f658aC9D466fDfF875d7353A0399bB5", "tokenId": "20"}'
> {"message":"NFT Purchased","txHash":"0x..."}
```

#### Get Listing Info
```bash
curl "http://localhost:3000/marketplace/listing/0x53B5F1de7f658aC9D466fDfF875d7353A0399bB5/20"
> {"price":"1.0","seller":"0x...","group":"1"}
```

#### Get Group Bid Info
```bash
curl "http://localhost:3000/marketplace/groupbid/1"
> {"price":"1.0","buyer":"0x..."}
```

#### Get Listed NFTs
```bash
curl "http://localhost:3000/marketplace/listed-nfts"
> {"listedNFTs":[{"nftContract":"0x...","tokenId":"20"}]}
```

## Contract Addresses (Sepolia)

- USDT: `0xAA26ff5dd04368916806d3cBf985fF41e023BF48`
- GameCoin: `0x359394D70Ca0565C9F5e85D9182ae62D4bcfE745`
- BCM: `0x53B5F1de7f658aC9D466fDfF875d7353A0399bB5`
- Marketplace: `0x1B8fC7DF8d0D97A25258a851dF95BAC20742C84c`
```
