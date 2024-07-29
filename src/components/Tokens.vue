<template>
  <section id="features" class="section has-company-bg">
    <div class="container is-10">
      <div class="columns reverse-row-order">
        <div class="column is-4">
          <img
              v-if="!loading"
              src="../assets/monster.png"
              width="100%"
              style="max-width: 50vw"
              alt=""
          />
          <img v-else src="../assets/moretokens.gif" width="100%"
               style="max-width: 50vw" alt=""/>
        </div>
        <div class="column is-5">
          <h3 class="pl-3 has-text-left is-size-3">
            More Tokens 🔥🔥🔥
          </h3>

          <div class="column">
            <div class="content">
              <b-message v-if="error" type="is-danger">
                {{ error }}
              </b-message>
            </div>
            <form @submit.prevent="moreTokens">
              <div class="field">
                <div class="control">
                  <label class="is-justify-content-left">Name</label>
                  <input
                      class="input is-primary"
                      type="text"
                      v-model="token.name"
                      placeholder="Token"
                  />
                </div>
              </div>
              <div class="field">
                <div class="control">
                  <label>Symbol</label>
                  <input
                      class="input is-primary"
                      type="text"
                      v-model="token.symbol"
                      placeholder="TKN"
                  />
                </div>
              </div>
              <div class="field">
                <div class="control">
                  <label>Owner's balance</label>
                  <input
                      class="input is-primary"
                      type="number"
                      v-model="token.balanceOwner"
                      maxlength="15"
                      placeholder="1000"
                  />
                </div>
              </div>
              <div class="field" v-if="isMobile">
                <div class="control">
                  <label>Owner's address</label>
                  <input
                      class="input is-primary"
                      type="text"
                      v-model="ownerAddress"
                      placeholder="ak_yourPublicKey"
                  />
                </div>
              </div>
              <progress
                  v-if="loading"
                  class="progress is-small is-primary"
                  max="100"
              >15%
              </progress>
              <b-button
                  native-type="submit"
                  class="is-rounded"
                  type="is-primary"
                  size="is-large"
              >Token 🚀
              </b-button
              >
            </form>
          </div>
        </div>
      </div>
      <div class="columns">
        <div class="column has-text-left is-offset-4">
          <div class="text-grey-dark has-text-weight-bold" v-if="hasDeployedTokens">$logger</div>
          <ul class="log-tokens">
            <li v-for="token in deployed" :key="token.name">
              name: <span class="has-text-weight-bold">{{ token.name }}</span><br/>
              address: <span class="has-text-weight-bold ae-contract-address">{{ token.address }}</span>
            </li>
          </ul>
          <div class="text-grey-dark has-text-weight-bold mt-4">$whoami <span v-if="isMobile">(prefunded account for you)</span>
          </div>
          <div v-if="addressResponse">
            <span class="mb-2 ae-address">
              {{ addressResponse.result }}
            </span>
            <div>
              <span class="text-grey-dark">💸 {{ getBalance }} AE</span>
            </div>
            <div>
              <span class="text-grey-dark">⛓️ {{ networkName }}</span>
            </div>
          </div>
          <div v-else>
            <div v-if="isMobile">
              Funding an account for you...
            </div>
            <div v-else>
              Connecting to wallet...
            </div>
          </div>

        </div>
      </div>
    </div>
  </section>
</template>

<script>
import {
  AeSdk,
  MemoryAccount,
  generateKeyPair,
  Node,
  AeSdkAepp,
  walletDetector,
  BrowserWindowMessageConnection, CompilerHttp
} from '@aeternity/aepp-sdk';
import FUNGIBLE_TOKEN_CONTRACT from 'aeternity-fungible-token/FungibleTokenFull.aes';

// Send wallet connection info to Aepp through content script
const nodes = [
  { name: 'ae_uat', instance: new Node('https://testnet.aeternity.io') },
  { name: 'ae_mainnet', instance: new Node('https://mainnet.aeternity.io') },
];

const errorAsField = async fn => {
  try {
    return { result: await fn };
  } catch (error) {
    return { error };
  }
};

export default {
  name: 'HomePage',
  data() {
    return {
      networkId: 'ae_mainnet',
      token: {
        name: null,
        decimals: 18,
        symbol: null,
        balanceOwner: null,
      },
      addressResponse: null,
      balance: null,
      deployed: [],
      loading: false,
      error: null,
      ownerAddress: null
    };
  },
  computed: {
    getBalance() {
      return this.convertToAE(this.balance);
    },
    networkName() {
      return this.networkId === 'ae_mainnet' ? 'Mainnet' : 'Testnet'
    },
    hasDeployedTokens() {
      return this.deployed.length > 0
    },
    isMobile() {
      return window.navigator.userAgent.includes('Mobi');
    },
  },
  methods: {
    convertToAE(balance) {
      return +(balance / 10 ** 18).toFixed(2);
    },
    logDeployed(name, deployed) {
      console.log(deployed);
      this.deployed.push({ name, address: deployed.address });
    },
    resetForm() {
      this.token = {
        name: null,
        decimals: 18,
        symbol: null,
        balanceOwner: null,
      };
    },
    async switchNetwork(networkId) {
      this.client.selectNode(networkId);
      this.networkId = networkId;
      console.log('switchNetwork', networkId);
      await this.updateData();
    },
    async moreTokens() {
      this.error = null;
      try {
        if (!this.token.name || !this.token.balanceOwner) {
          this.error = '⚠️ Oops ... fields are required.';
          return;
        }
        this.loading = true;
        const { name, decimals, symbol, balanceOwner } = this.token;
        const contract = await this.client.initializeContract({
          sourceCode: FUNGIBLE_TOKEN_CONTRACT
        });
        const init = await contract.$deploy([
          name,
          decimals,
          symbol,
          `${balanceOwner}${'0'.repeat(decimals)}`,
        ]);
        if (this.isMobile && this.ownerAddress) {
          contract.methods.transfer(
              this.ownerAddress,
              `${balanceOwner}${'0'.repeat(decimals)}`
          )
        }
        this.logDeployed(name, init);
        this.resetForm();
        this.loading = false;
      } catch (error) {
        console.error(error);
        this.loading = false;
        this.error = '⚠️ Oops ... something went wrong.';
      }
    },
    async getNetworkId()  {
      return (await this.client.getNodeInfo()).nodeNetworkId;
    },
    async updateData() {
      this.pub = await this.client.address;
      this.balance = await this.client.getBalance(this.pub);
      this.addressResponse = await errorAsField(this.client.address);
      this.networkId = await this.getNetworkId();
    },
    async connectToWallet(wallet) {
      const { networkId } = await this.client.connectToWallet(wallet.getConnection());
      await this.client.subscribeAddress('subscribe', 'connected');
      if (networkId && await this.getNetworkId() !== networkId) {
        await this.switchNetwork(networkId);
      } else {
        await this.updateData();
      }
    },
    async scanForWallets() {
      try {
        const handleWallets = async function ({ wallets, newWallet }) {
          newWallet = newWallet || Object.values(wallets)[0];
          stopScan();
          await this.connectToWallet(newWallet);
        };

        const scannerConnection = new BrowserWindowMessageConnection({
          connectionInfo: { id: 'spy' },
        });
        const stopScan = walletDetector(scannerConnection, handleWallets.bind(this));
      } catch (e) {
        console.log(e);
      }
    },
    async initNode() {
      const that = this;

      this.client = new AeSdkAepp({
        name: 'More Tokens',
        nodes,
        onCompiler: new CompilerHttp('https://v8.compiler.aepps.com'),
        async onNetworkChange(params) {
          if ((await this.getNodeInfo()).nodeNetworkId !== params.networkId) {
            console.log(
                `Detected wallet network switch. Trying to initialize node for ${params.networkId}`,
            );
            that.switchNetwork(params.networkId);
          }
        },
        onAddressChange: async addresses => {
          console.log(addresses);
          this.pub = await this.client.address;
          this.balance = await this.client.balance(this.pub).catch(e => {
            console.log(e);
            return 0;
          });
          this.addressResponse = await errorAsField(this.client.address);
        },
        onDisconnect(a) {
          console.log('disconnect');
          console.log(a);
        },
      });
      this.height = await this.client.height;

      // Start looking for wallets
      await this.scanForWallets();
    },
    async initTestnetSDK() {
      // try to read account
      let keypair = JSON.parse(localStorage.getItem('accountKey') || '{}');
      if (!keypair.publicKey) {
        keypair = generateKeyPair();
        localStorage.setItem('accountKey', JSON.stringify(keypair));
        // fund account
        console.log("funding account")
        await fetch('https://faucet.aeternity.io/account/' + keypair.publicKey, {
          method: 'POST'
        })
        console.log("funding account finished")
      }

      // create client
      this.client = new AeSdk({
        nodes,
        onCompiler: new CompilerHttp('https://v8.compiler.aepps.com'),
      });
      this.client.addAccount(
          new MemoryAccount({ keypair }), { select: true })
      this.height = await this.client.height();
      console.log('height', this.height);

      this.updateData()
    },

  },
  async created() {
    if (this.isMobile) {
      this.initTestnetSDK();
    } else {
      this.initNode(this.networkId);
    }
  },
};
</script>

<style scoped>
.ae-address {
  overflow-wrap: anywhere;
}

.ae-contract-address {
  overflow-wrap: anywhere;
}

.ae-address li {
  list-style: none;
}
</style>
