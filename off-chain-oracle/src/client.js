require("dotenv").config();

import {
  createRequest
} from "./ethereum";
import { REQUEST_PARAM } from "./config";


const start = () => {

  let requestType = process.env.REQUEST_TYPE;

  createRequest({
      requestType,
      params: REQUEST_PARAM
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