const fs = require('fs'); // Built-in dependency for file streaming.
const solc = require('solc'); // Our Solidity compiler
const Web3 = require('web3');


const content = fs.readFileSync('lz.t.sol', 'utf-8');

// Format the input for solc compiler:
const input = {
  language: 'Solidity',
  sources: {
    'lz.t.sol' : {
      "content": content // The imported content
    }
  },
  settings: {
    outputSelection: {
      '*': {
        '*': ['*']
      }
    }
  }
}; 

const output = JSON.parse(solc.compile(JSON.stringify(input)));

// Set up a provider
const provider = new Web3.providers.HttpProvider("http://localhost:8545");

// Connect to the network and save it as "web3"
const web3 = new Web3(provider);

// Get the compiled contract's abi (interface)
const Contract = output.contracts["lz.t.sol"];


const { abi, evm } = Contract.Test

// Initialize a new contract object:
const contract = new web3.eth.Contract(abi);

console.log("compiled output");

function deployAndRunContract() {
	web3.eth.getAccounts().then(function(addresses) {
		web3.eth.getGasPrice().then(function(gasPrice) {
			contract.deploy({
				data: evm.bytecode.object,
			})
			.send({
				from: addresses[0],
				gas: 1000000,
				gasPrice,
			})
			.on('error', function(err) {
				console.log("Failed to deploy:", err) 
			}).then(function(newContract) {
				console.log("[WARN]: exploitable contract");
				newContract.methods.ext().call({
					from: addresses[1],
					gas: 1000000,
					gasPrice,
				}).then(function(receipt) {
					console.log("[receipt]: we get back " + receipt);
				});
			})
		})
	})
}

deployAndRunContract();
