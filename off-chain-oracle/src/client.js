require("dotenv").config();

import {
  createRequest
} from "./ethereum";
import client_config from './client_config.json';

const start = () => {

  const queries = JSON.stringify(client_config.queries);

  createRequest({
    queries,
    qtype: client_config["type"] === 'query' ? 0 : 1,
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