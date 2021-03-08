import startOracle from "./oracle";
import startConsumer from "./consumer";
import startClient from "./client";

startOracle();

var intv = setInterval(() => {
    clearInterval(intv);
    startConsumer();
    startClient();
}, 5000);
