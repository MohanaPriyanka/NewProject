/**
 * Created by rebeccanachison on 10/28/21.
 */

const accountInputMask = (currentValue, regexGroupsInput, format, prefixInput, length) => {
    const prefix = prefixInput ? prefixInput : '';

    //remove prefix before formatting
    if (prefix.length && prefix.length <= currentValue.length && currentValue.slice(0,prefix.length) === prefix) {
        currentValue = currentValue.slice(prefix.length);
    }
    //remove partial prefix if user is attempting to type or delete prefix
    if (prefix.length && currentValue.length < prefix.length && prefix.slice(0,currentValue.length) === currentValue) {
        currentValue = '';
    }

    //if no special format, return current string with prefix
    if (!regexGroupsInput || !format || !length) {
        return prefix + currentValue;
    }

    //convert regex groups string to regex
    const regexGroups = new RegExp(regexGroupsInput);
    const delimiters = format.split(/\$\d/);
    let maskedValue = '';

    //strip out non-digits and place into desired format
    const captureGroups = currentValue.replace(/\D+/g, '').match(regexGroups);
    // check if input is complete
    const isComplete = currentValue.length >= length - prefix.length;

    //loop through delimiters and capture groups to build input in desired format
    /* Notes:
    * Delimiters always start first and end last. Splitting the format string will always put an array element on either side of the separator, even if it's just '';
    * We start iterating at captureGroups[1] because captureGroups[0] is equal to the full string.
     */
    for (let i = 0; i < delimiters.length; i++) {
        //if there is a corresponding capture group OR the input is complete and we're placing the final delimiter OR there is no input
        if ((i + 1 < captureGroups.length && captureGroups[i + 1]) || (isComplete && i + 1 === captureGroups.length) || !captureGroups[0]) {
            maskedValue += delimiters[i];
        }
        if (captureGroups[i + 1]) {
            maskedValue += captureGroups[i + 1];
        }
        //end loop if the input is not complete, but there is no more input so far
        if (i + 1 < captureGroups.length && !captureGroups[i + 1]) {
            break;
        }
    }

    return maskedValue;
};

export {accountInputMask}