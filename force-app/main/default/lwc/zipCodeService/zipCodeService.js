/**
 * Created by peteryao on 2/5/20.
 */
import {makeRequest} from 'c/httpRequestService';

const getZipCodeCapacity = (zipCode, partnerId, utilityId) => {
    let calloutURI = '/apply/services/apexrest/v3/zip-check?zipCode='+zipCode;
    if (partnerId) {
        calloutURI += '&partnerId=' + partnerId;
    }
    if(utilityId) {
        calloutURI += '&utilityId=' + utilityId;
    }
    return makeRequest(calloutURI, 'GET');
};

export {getZipCodeCapacity}