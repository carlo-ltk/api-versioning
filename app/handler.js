'use strict';

module.exports.ping = async (event) => {

  //const versions = JSON.parse(process.env.versions)
  //console.log(versions)
  const stage = process.env.stage
  //const version = versions.filter( (item) => item.stage == stage).shift().tag

  return {
    statusCode: 200,
    body: JSON.stringify(
      {
        message: `Hey there, I'm the ping function and I executed successfully!\n
        (${process.env.stage})`,
        // input: event,
      },
      null,
      2
    ),
  }
}
