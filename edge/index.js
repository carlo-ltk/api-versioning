const apiVersionHeaderName = "api-version"

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

            if(!hasValue(request.headers[apiVersionHeaderName])){
                return request
            }

            const requestedVersion = request.headers[apiVersionHeaderName][0].value
            
           if (!(requestedVersion in mapping)) {
                return { status: '403', statusDescription: `requested version (${requestedVersion}) is not available`};
            }

            const version = JSON.parse(mapping[requestedVersion])
            
            const destDomain = `${version.apigw}.execute-api.us-east-1.amazonaws.com`
            const destPath = `/${version.commit}`

            if (destDomain === request.origin.custom.domainName) {
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
            return request
        default:
            throw new Error(`Unhandled eventType [${eventType}]`)
    }
  }