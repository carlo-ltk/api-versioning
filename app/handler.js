'use strict';

const { SSMClient, GetParameterCommand } = require("@aws-sdk/client-ssm");

module.exports.ping = async (event) => {

  const stage = process.env.stage
  const ssmClient = new SSMClient()
  const ssmParams = { Name: "fnd-api-s2-versions"}
  const ssmCommand = new GetParameterCommand(ssmParams)
  let version = null

  try {
    const versionsData =  await ssmClient.send(ssmCommand)
    console.log(versionsData)
    const versions = JSON.parse(versionsData.Parameter.Value)
    version = versions.filter(item => item.stage === stage).shift()
  } catch (error) {
    console.error(error)
  }
  
  return {
    statusCode: 200,
    body: JSON.stringify(
      {
        message: `Hey there, I'm the ping function and I executed successfully! Version: ${ version ? version.tag : "N/A"} (${process.env.stage})`,
        // input: event,
      },
      null,
      2
    ),
    headers: {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token,X-Amz-User-Agent,X-Amzn-Trace-Id,Api-Version' 
    }
  }
}
