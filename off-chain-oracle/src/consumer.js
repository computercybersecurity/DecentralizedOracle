import {
  updatedRequest,
  newRequest
} from "./ethereum.js";

const consume = () => {
  updatedRequest((error, event) => {
    console.log(error, event.returnValues)
    console.log("UPDATE REQUEST DATA EVENT ON SMART CONTRACT");
    // console.log("BLOCK NUMBER: ");
    // console.log("  " + result.blockNumber)
    // console.log("UPDATE REQUEST DATA: ");
    // console.log(result.args);
    console.log("\n");
  });

  newRequest((error, event) => {
    console.log(error, event.returnValues);
    console.log("NEW REQUEST DATA EVENT ON SMART CONTRACT");
    // console.log("BLOCK NUMBER: ");
    // console.log("  " + result.blockNumber)
    // console.log("NEW REQUEST DATA: ");
    // console.log(result.args);
    console.log("\n");
  });
};

export default consume;