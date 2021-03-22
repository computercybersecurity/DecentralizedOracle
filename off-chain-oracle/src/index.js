import startOracle from "./oracle.js";
import startConsumer from "./consumer.js";
// import startClient from "./client.js";

startOracle();

var intv = setInterval(() => {
    clearInterval(intv);
    startConsumer();
    // startClient();
}, 5000);
