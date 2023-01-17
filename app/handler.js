'use strict';

const { SSMClient, GetParameterCommand } = require("@aws-sdk/client-ssm");

module.exports.ping = async (event) => {

  const stage = process.env.stage
  const ssmClient = new SSMClient()
  const ssmParams = { Name: "fnd-api-s2-versions"}
  const ssmCommand = new GetParameterCommand(ssmParams)

  try {
    const versions =  await ssmClient.send(ssmCommand)
    console.log(versions)
  } catch (error) {
    console.error(error)
  }
  
  return {
    statusCode: 200,
    body: JSON.stringify(
      {
        message: `-- Hey there, I'm the ping function and I executed successfully!\n
        (${process.env.stage})`,
        // input: event,
      },
      null,
      2
    ),
  }
}
