// testContractInteraction.js
const { ethers } = require('ethers');

// InfuraのSepoliaテストネット RPC URL
const provider = new ethers.JsonRpcProvider('https://sepolia.infura.io/v3/edb21febc56648be87babedccd5fe088');

// コントラクトのABI（TestUSDTコントラクト）
const abi = [
{
"inputs": [],
"stateMutability": "nonpayable",
"type": "constructor"
},
{
"inputs": [
  {
    "internalType": "address",
    "name": "spender",
    "type": "address"
  },
  {
    "internalType": "uint256",
    "name": "allowance",
    "type": "uint256"
  },
  {
    "internalType": "uint256",
    "name": "needed",
    "type": "uint256"
  }
],
"name": "ERC20InsufficientAllowance",
"type": "error"
},
{
"inputs": [
  {
    "internalType": "address",
    "name": "sender",
    "type": "address"
  },
  {
    "internalType": "uint256",
    "name": "balance",
    "type": "uint256"
  },
  {
    "internalType": "uint256",
    "name": "needed",
    "type": "uint256"
  }
],
"name": "ERC20InsufficientBalance",
"type": "error"
},
{
"inputs": [
  {
    "internalType": "address",
    "name": "approver",
    "type": "address"
  }
],
"name": "ERC20InvalidApprover",
"type": "error"
},
{
"inputs": [
  {
    "internalType": "address",
    "name": "receiver",
    "type": "address"
  }
],
"name": "ERC20InvalidReceiver",
"type": "error"
},
{
"inputs": [
  {
    "internalType": "address",
    "name": "sender",
    "type": "address"
  }
],
"name": "ERC20InvalidSender",
"type": "error"
},
{
"inputs": [
  {
    "internalType": "address",
    "name": "spender",
    "type": "address"
  }
],
"name": "ERC20InvalidSpender",
"type": "error"
},
{
"anonymous": false,
"inputs": [
  {
    "indexed": true,
    "internalType": "address",
    "name": "owner",
    "type": "address"
  },
  {
    "indexed": true,
    "internalType": "address",
    "name": "spender",
    "type": "address"
  },
  {
    "indexed": false,
    "internalType": "uint256",
    "name": "value",
    "type": "uint256"
  }
],
"name": "Approval",
"type": "event"
},
{
"anonymous": false,
"inputs": [
  {
    "indexed": true,
    "internalType": "address",
    "name": "from",
    "type": "address"
  },
  {
    "indexed": true,
    "internalType": "address",
    "name": "to",
    "type": "address"
  },
  {
    "indexed": false,
    "internalType": "uint256",
    "name": "value",
    "type": "uint256"
  }
],
"name": "Transfer",
"type": "event"
},
{
"inputs": [
  {
    "internalType": "address",
    "name": "owner",
    "type": "address"
  },
  {
    "internalType": "address",
    "name": "spender",
    "type": "address"
  }
],
"name": "allowance",
"outputs": [
  {
    "internalType": "uint256",
    "name": "",
    "type": "uint256"
  }
],
"stateMutability": "view",
"type": "function"
},
{
"inputs": [
  {
    "internalType": "address",
    "name": "spender",
    "type": "address"
  },
  {
    "internalType": "uint256",
    "name": "value",
    "type": "uint256"
  }
],
"name": "approve",
"outputs": [
  {
    "internalType": "bool",
    "name": "",
    "type": "bool"
  }
],
"stateMutability": "nonpayable",
"type": "function"
},
{
"inputs": [
  {
    "internalType": "address",
    "name": "account",
    "type": "address"
  }
],
"name": "balanceOf",
"outputs": [
  {
    "internalType": "uint256",
    "name": "",
    "type": "uint256"
  }
],
"stateMutability": "view",
"type": "function"
},
{
"inputs": [],
"name": "decimals",
"outputs": [
  {
    "internalType": "uint8",
    "name": "",
    "type": "uint8"
  }
],
"stateMutability": "view",
"type": "function"
},
{
"inputs": [
  {
    "internalType": "address",
    "name": "to",
    "type": "address"
  },
  {
    "internalType": "uint256",
    "name": "amount",
    "type": "uint256"
  }
],
"name": "mint",
"outputs": [],
"stateMutability": "nonpayable",
"type": "function"
},
{
"inputs": [],
"name": "name",
"outputs": [
  {
    "internalType": "string",
    "name": "",
    "type": "string"
  }
],
"stateMutability": "view",
"type": "function"
},
{
"inputs": [],
"name": "owner",
"outputs": [
  {
    "internalType": "address",
    "name": "",
    "type": "address"
  }
],
"stateMutability": "view",
"type": "function"
},
{
"inputs": [],
"name": "symbol",
"outputs": [
  {
    "internalType": "string",
    "name": "",
    "type": "string"
  }
],
"stateMutability": "view",
"type": "function"
},
{
"inputs": [],
"name": "totalSupply",
"outputs": [
  {
    "internalType": "uint256",
    "name": "",
    "type": "uint256"
  }
],
"stateMutability": "view",
"type": "function"
},
{
"inputs": [
  {
    "internalType": "address",
    "name": "to",
    "type": "address"
  },
  {
    "internalType": "uint256",
    "name": "value",
    "type": "uint256"
  }
],
"name": "transfer",
"outputs": [
  {
    "internalType": "bool",
    "name": "",
    "type": "bool"
  }
],
"stateMutability": "nonpayable",
"type": "function"
},
{
"inputs": [
  {
    "internalType": "address",
    "name": "from",
    "type": "address"
  },
  {
    "internalType": "address",
    "name": "to",
    "type": "address"
  },
  {
    "internalType": "uint256",
    "name": "value",
    "type": "uint256"
  }
],
"name": "transferFrom",
"outputs": [
  {
    "internalType": "bool",
    "name": "",
    "type": "bool"
  }
],
"stateMutability": "nonpayable",
"type": "function"
}
];

// コントラクトのアドレス
const contractAddress = '0x626D995696d13c20e49F0987B43c906cb40C27C9';

// コントラクトインスタンスを作成
const contract = new ethers.Contract(contractAddress, abi, provider);

// 例: 特定アドレスの残高を取得する関数
async function getBalance(address) {
  try {
    const balance = await contract.balanceOf(address);
    console.log(`Balance of ${address}: ${ethers.utils.formatUnits(balance, 18)} USDT`);
  } catch (error) {
    console.error('Error:', error);
  }
}

// テストするアドレスを指定
const testAddress = '0xYourTestAddressHere';  // テストしたいアドレスに置き換えてください
getBalance(testAddress);
