'use strict';

module.exports.ping = async (event) => {
  return {
    statusCode: 200,
    body: JSON.stringify(
      {
        message: `Hey there, I'm the ping function and I executed successfully! (${process.env.version})`,
        // input: event,
      },
      null,
      2
    ),
  }
}
