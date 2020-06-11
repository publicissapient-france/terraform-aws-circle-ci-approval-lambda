const https = require('https');

const callCircleCiHttps = async (method, workflowId, pathSuffix) => {

  const options = {
    'method': method,
    'hostname': 'circleci.com',
    'path': '/api/v2/workflow/' + workflowId + pathSuffix,
    'headers': {
      'Circle-Token': process.env.CIRCLE_CI_TOKEN
    }
  };

  return new Promise((resolve, reject) => {
    const req = https.request(options, function(res) {
      res.setEncoding('utf8');

      let responseBody = '';
      res.on('data', (chunk) => {
        responseBody += chunk;
      });
      res.on('end', () => {
        if (res.statusCode === 200) {
          resolve(JSON.parse(responseBody));
        } else {
          resolve({
            httpStatusCode: res.statusCode
          })
        }
      });

      res.on("error", function(error) {
        console.error(error);
      });
    });

    req.end();
  })
}



/**
 * Pass the data to send as `event.data`, and the request options as
 * `event.options`. For more information see the HTTPS module documentation
 * at https://nodejs.org/api/https.html.
 *
 * Will succeed with the response body.
 */
exports.handler = async (event, context, callback) => {
  const workflowId = event.queryStringParameters["workflowId"]
  const getWorkflow = await callCircleCiHttps('GET', workflowId, '/job')
  var jobId

  // the code you're looking for
  var needle = 'approval';

  // iterate over each element in the array
  for (var i = 0; i < getWorkflow.items.length; i++) {
    // look for the entry with a matching `code` value
    if (getWorkflow.items[i].type == needle) {
      // we found it
      jobId = getWorkflow.items[i].id
    }
  }
  const approveCode = await callCircleCiHttps('POST', workflowId, '/approve/' + jobId)
  callback(null, approveCode);
};