/**
 * Created by peteryao on 2/5/20.
 */
const getZipCodeCapacity = (zipCode, partnerId) => {
    return new Promise(function(resolve, reject) {
        let calloutURI = '/apply/services/apexrest/v3/zip-check?zipCode='+zipCode;
        if (partnerId) {
            calloutURI += '&partnerId=' + partnerId;
        }
        // Could use fetch instead of XMLHttpRequest, but it's not supported by IE11
        const xmlHttpRequest = new XMLHttpRequest();
        xmlHttpRequest.onreadystatechange = function() {
            if (this.readyState === 4) {
                if (this.status === 200) {
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
        xmlHttpRequest.open('GET', calloutURI, true);
        xmlHttpRequest.send();
    });
};

export {getZipCodeCapacity}