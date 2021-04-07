require("dotenv").config();

import {
  createRequest
} from "./ethereum.js";
import client_config from './client_config.js';

const start = () => {

  const queries = JSON.stringify(client_config.queries);

  createRequest({
    queries,
    contractAddr: client_config["contractAddr"]
  })
  .then(restart)
  .catch(error);
};

const restart = () => {
  wait(process.env.TIMEOUT).then(start);
};

const wait = (milliseconds) => {
  return new Promise((resolve, reject) => setTimeout(() => resolve(), milliseconds));
};

const error = (error) => {
  console.error(error);
  restart();
};

export default start;