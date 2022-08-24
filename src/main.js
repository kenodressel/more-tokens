import Buefy from 'buefy';
import 'buefy/dist/buefy.css';
import Vue from 'vue';
import App from './App.vue';

Vue.config.productionTip = false;
Vue.use(Buefy);

new Vue({
  render: h => h(App),
}).$mount('#app');
