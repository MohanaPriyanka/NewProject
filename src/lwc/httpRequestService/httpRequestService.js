/**
 * Created by PeterYao on 3/11/2020.
 */

const makeRequest = (calloutURI, method, options) => {
    return new Promise(function(resolve, reject) {
        const xmlHttpRequest = new XMLHttpRequest();
        xmlHttpRequest.onreadystatechange = function() {
            if (this.readyState === 4) {
                if (this.status === 200 || this.status === 201) {
                    const zipCodeResponse = JSON.parse(this.responseText);
                    if (zipCodeResponse.data) {
                        resolve(zipCodeResponse.data);
                    } else {
                        reject(this.responseText);
                    }
                } else {
                    reject(this.responseText);
                }
            }
        };
        xmlHttpRequest.open(method, calloutURI, true);
        if (options && options.headers) {
            xmlHttpRequest.setRequestHeader(options.headers.name, options.headers.value);
        }
        if (options && options.body) {
            xmlHttpRequest.send(options.body);
        } else {
            xmlHttpRequest.send();
        }
    });
};

export {makeRequest}