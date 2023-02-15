module.exports.handler = async (event) => {
  console.log("Event: ", event);
  console.log("env: " + process.env.ENV_VAL);
  return {
    statusCode: 200,
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      message: process.env.ENV_VAL,
    }),
  };
};
