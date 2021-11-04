/**
 * Created by rebeccanachison on 10/28/21.
 */

const accountInputMask = (currentValue, regexGroupsInput, format, prefixInput, length) => {
    const prefix = prefixInput ? prefixInput : '';
    //convert regex groups string to regex
    const regexGroups = new RegExp(regexGroupsInput);
    const delimiters = format.split(/\$\d/);
    let maskedValue = '';

    //remove prefix before formatting
    if (prefix.length && prefix.length <= currentValue.length && currentValue.slice(0,prefix.length) === prefix) {
        currentValue = currentValue.slice(prefix.length);
    }
    //remove partial prefix if user is attempting to type or delete prefix
    if (prefix.length && currentValue.length < prefix.length && prefix.slice(0,currentValue.length) === currentValue) {
        currentValue = '';
    }
    //strip out non-digits and place into desired format
    const captureGroups = currentValue.replace(/\D+/g, '').match(regexGroups);
    const isFinal = currentValue.length >= length - prefix.length;

    for (let i = 0; i < delimiters.length; i++) {
        if ((i + 1 < captureGroups.length && captureGroups[i + 1]) || (isFinal && i + 1 === captureGroups.length) || !captureGroups[0]) {
            maskedValue += delimiters[i];
        }
        if (captureGroups[i + 1]) {
            maskedValue += captureGroups[i + 1];
        }
        if (i + 1 < captureGroups.length && !captureGroups[i + 1]) {
            break;
        }
    }

    return maskedValue;
};

export {accountInputMask}