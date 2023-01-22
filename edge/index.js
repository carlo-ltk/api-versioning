const apiVersionHeaderName = "Api-Version"
const fallbackVersion = "stable"

const fs = require('fs');
const mapping = JSON.parse(fs.readFileSync('./config.json'))

function hasValue(mappings){
    if(typeof mappings === 'undefined') return false;
    if(mappings === null) return false;
    return true;
}

exports.handler = async (event) => {
    
    const cf = event.Records[0].cf
    const eventType = cf.config.eventType
    const request = cf.request

    switch (eventType) {
        case 'origin-request':

            console.log(request)

            if(!hasValue(request.headers[apiVersionHeaderName])){
                console.log(`Origin request has no ${apiVersionHeaderName} header, returning request as it is`)
                return request
            }
            let requestedVersion = request.headers[apiVersionHeaderName][0].value
            console.log(`Requested versions is ${requestedVersion}`)
            
           if (!(requestedVersion in mapping)) {
                //return { status: '403', statusDescription: `requested version (${requestedVersion}) is not available`};
                console.log(`Version ${requestedVersion} not found in mapping, default to ${fallbackVersion}`)
                requestedVersion = fallbackVersion
            }

            const version = JSON.parse(mapping[requestedVersion])
            console.log(`Matching version: ${version}`)
            
            const destDomain = `${version.apigw}.execute-api.us-east-1.amazonaws.com`
            const destPath = `/${version.stage}`

            if (destDomain === request.origin.custom.domainName) {
                console.log(`destDomain ${destDomain} match ${request.origin.custom.domainName} return request as it is`)
                return request
            }

            request.origin = {
                custom: {
                    domainName: destDomain,
                    port: 443,
                    protocol: 'https',
                    path: destPath,
                    sslProtocols: [
                        'TLSv1',
                        'TLSv1.1',
                        'TLSv1.2'
                    ],
                    readTimeout: 30,
                    keepaliveTimeout: 5,
                    customHeaders: {}
                }
            };
        
            request.headers['host'] = [{ key: 'host', value: destDomain}];
            console.log(`Altered request is: ${request}`)
            return request
        default:
            throw new Error(`Unhandled eventType [${eventType}]`)
    }
  }