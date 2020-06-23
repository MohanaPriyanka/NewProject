({
    getLicenseType : function(component) {
        var action = component.get("c.getLicenseType");
        action.setCallback(this,function(resp){
            if(resp.getState() == 'SUCCESS') {
                if(resp.getReturnValue().length > 0){
                    component.set("v.licenseType", resp.getReturnValue());
                }
            }
            else {
                $A.log("Errors", resp.getError());
            }
        });
        $A.enqueueAction(action);
    },

    callApexMethod : function(component, methodName, setAttribute, setStorable) {
        var action = component.get("c." + methodName);
        var i;
        action.setCallback(this,function(resp){
            if(resp.getState() == 'SUCCESS') {
               for (i=0; i<setAttribute.length; i++) {
                    component.set("v." + setAttribute[i], resp.getReturnValue());
                }
            }
            else {
                $A.log("Errors", resp.getError());
            }
        });
        $A.enqueueAction(action);

        if (setStorable) {
            action.setStorable;
        }
    },

    getPicklistOptions : function(component, objectName, fieldName, inputSelect) {
        this.setAttributeWithPicklistOptions(component, objectName, fieldName, inputSelect, 'v.options');
    },

    setAttributeWithPicklistOptions : function(component, objectName, fieldName, inputSelect, attributeName) {
        var promise = new Promise(function(resolve) {
            var action = component.get("c.getPicklistFields");
            action.setParams({"objectName": objectName,
                "fieldName": fieldName});
            action.setStorable();
            var opts=[];
            action.setCallback(this, function(a) {
                for (var i=0; i< a.getReturnValue().length; i++) {
                    opts.push({"class": "optionClass", label: a.getReturnValue()[i], value: a.getReturnValue()[i]});
                }
                inputSelect.set(attributeName, opts);
                return(resolve);
            });
            $A.enqueueAction(action);
        });
        return promise;
    },

    setListAttributeWithPicklistOptions : function(component, objectName, fieldName, attribute) {
        var promise = new Promise(function(resolve) {
            var action = component.get("c.getPicklistFields");
            action.setParams({"objectName": objectName,
                "fieldName": fieldName});
            action.setStorable();
            var opts=[];
            action.setCallback(this, function(a) {
                for (var i=0; i< a.getReturnValue().length; i++) {
                    opts.push({"text": a.getReturnValue()[i]});
                }

                component.set(attribute, opts);
            });
            $A.enqueueAction(action);
        });
        return promise;
    },

    US_STATES : {'AL':'Alabama', 'AK':'Alaska', 'AZ':'Arizona', 'AR':'Arkansas', 'CA':'California', 
                 'CO':'Colorado', 'CT':'Connecticut', 'DE':'Delaware', 'FL':'Florida', 'GA':'Georgia', 
                 'HI':'Hawaii', 'ID':'Idaho', 'IL':'Illinois', 'IN':'Indiana', 'IA':'Iowa', 'KS':'Kansas', 
                 'KY':'Kentucky', 'LA':'Louisiana', 'ME':'Maine', 'MD':'Maryland', 'MA':'Massachusetts', 
                 'MI':'Michigan', 'MN':'Minnesota', 'MS':'Mississippi', 'MO':'Missouri', 'MT':'Montana', 
                 'NE':'Nebraska', 'NV':'Nevada', 'NH':'New Hampshire', 'NJ':'New Jersey', 'NM':'New Mexico', 
                 'NY':'New York', 'NC':'North Carolina', 'ND':'North Dakota', 'OH':'Ohio', 'OK':'Oklahoma', 
                 'OR':'Oregon', 'PA':'Pennsylvania', 'RI':'Rhode Island', 'SC':'South Carolina', 
                 'SD':'South Dakota', 'TN':'Tennessee', 'TX':'Texas', 'UT':'Utah', 'VT':'Vermont', 'VA':'Virginia', 
                 'WA':'Washington', 'WV':'West Virginia', 'WI':'Wisconsin', 'WY':'Wyoming'},

    getUSStates : function(component, attr, abbreviated) {
        var action = component.get("c.getUSStates");
        action.setParams({"abbreviated": abbreviated});
        action.setStorable();
        var opts=[];
        action.setCallback(this, function(a) {
            for (var i=0;i< a.getReturnValue().length;i++) {
                opts.push(a.getReturnValue()[i]);
            }
            component.set(attr, opts);
        });
        $A.enqueueAction(action);
    },

    saveSObject : function(component, id, objectName, field, value, objToUpdate) {
        return this.saveSObjectErrorOption(component, id, objectName, field, value, objToUpdate, {suppressAlert: false});
    },

    saveSObjectErrorOption : function(component, id, objectName, field, value, objToUpdate, messageOption) {
        let stacktrace = this.getStackTrace();
        return new Promise(function(resolve, reject) {
            var sobj = new Object();
            if (!objToUpdate) {
                sobj = {'sobjectType': objectName,
                        'Id': id};
                sobj[field] = value;
            } else {
                sobj = objToUpdate;
            }
            var action = component.get("c.updateSObject");
            action.setParams({"sobj": sobj});
            action.setCallback(this, function(resp) {
                if (resp.getState() === "SUCCESS") {
                    var retVal = resp.getReturnValue();
                    resolve(retVal);
                } else if (resp.getState() === "ERROR") {
                    var appEvent = $A.get("e.c:ApexCallbackError");
                    appEvent.setParams({
                        "className" : "BlueWaveParentHelper",
                        "methodName" : "updateSObject",
                        "errors" : resp.getError(),
                        "developerInfo" : sobj,
                        "options" : messageOption,
                        "stacktrace" : stacktrace
                    });
                    appEvent.fire();                    
                    reject(resp.getError());
                } else {
                    reject(Error("Unknown error"));
                }
            });
            $A.enqueueAction(action);
        });
    },

    insertSObject : function(component, sObject) {
        let stacktrace = this.getStackTrace();
        return new Promise(function(resolve, reject) {
            var action = component.get("c.insertSObject");
            action.setParams({"sobj": sObject});
            action.setCallback(this, function(resp) {
                if (resp.getState() === "SUCCESS") {
                    var retVal = resp.getReturnValue();
                    resolve(retVal);
                } else if (resp.getState() === "ERROR") {
                    var appEvent = $A.get("e.c:ApexCallbackError");
                    appEvent.setParams({
                        "className" : "BlueWaveParentHelper",
                        "methodName" : "insertSObject",
                        "errors" : resp.getError(),
                        "developerInfo" : sObject,
                        "stacktrace" : stacktrace
                    });
                    appEvent.fire();
                    reject(resp.getError());
                } else {
                    reject(Error("Unknown error"));
                }
            });
            $A.enqueueAction(action);
        });
    },

    MAX_FILE_SIZE: 4500000, /* 6 000 000 * 3/4 to account for base64 */
    CHUNK_SIZE: 400000,
    BYTES_IN_MB: 1000000,
    precisionRound : function(number, precision) {
        var factor = Math.pow(10, precision);
        return Math.round(number * factor) / factor;
    },
    /*
       CHUNK_SIZE: Use a multiple of 4. 950000 in the blog post didn't work,
       81250 works except for one test file, 40000 seems to work ok...
    */
    // http://peterknolle.com/file-upload-lightning-component/
    // Assumes callbackFunc takes a component as an argument - not sure if that will always work...
    uploadFiles : function(component, files, parentId, callbackFunc, description, helper, showInModal) {
        var ltg = this;
        for (var i=0; i<files.length; i=i+1) {
            (function(file) {
                if (file.size > ltg.MAX_FILE_SIZE) {
                    let message = 'We\'re sorry, we cannot handle files this large in this portal. \n';
                    message += 'We\'ll open a Box Upload Widget in a new window. Please make sure your popup blocker is disabled\n\n';
                    message += 'File size cannot exceed: ' + helper.precisionRound(ltg.MAX_FILE_SIZE/ltg.BYTES_IN_MB,2) + ' MB.\n';
                    message += 'Your file size is: ' + helper.precisionRound(file.size/ltg.BYTES_IN_MB,2) + ' MB.';
                    if (!showInModal) {
                        helper.showNotice(component, helper.openBoxUploader, 'File Too Large', message, description);
                        component.set('v.isLargeFile', true);
                    } else {
                        alert(message);
                        helper.openBoxUploader(description);
                    }
                    return;
                }
                var fr = new FileReader();

       	        fr.onload = function() {
                    var fileContents = fr.result;
                    var base64Mark = 'base64,';
                    var dataStart = fileContents.indexOf(base64Mark) + base64Mark.length;

                    fileContents = fileContents.substring(dataStart);

                    ltg.upload(component, file, fileContents, parentId, description).then(
                        $A.getCallback(function resolve() {
                            if (callbackFunc) {
                                callbackFunc(component, helper);
                            }
                        }),
                        function(error) {
                            var appEvent = $A.get("e.c:ApexCallbackError");
                            appEvent.setParams({"className" : "BlueWaveParentHelper",
                                                "methodName" : "uploadFiles",
                                                "errors" : error});
                            appEvent.fire();
                        }
                    )
                };

                fr.readAsDataURL(file);
            })(files[i]);
        }
    },

    upload: function(component, file, fileContents, parentId, description) {
        var fromPos = 0;
        var toPos = Math.min(fileContents.length, fromPos + this.CHUNK_SIZE);

        // start with the initial chunk
        var ltg = this;
        return new Promise($A.getCallback(function(resolve, reject) {
            ltg.uploadChunk(component, file, fileContents, parentId, fromPos, toPos, '', resolve, reject, description);
        }));
    },

    uploadChunk : function(component, file, fileContents, parentId, fromPos, toPos, attachId, resolveCallback, rejectCallback, description) {
        var action = component.get("c.saveTheChunkWithDescription");
        var chunk = fileContents.substring(fromPos, toPos);

        action.setParams({
            parentId: parentId,
            fileName: file.name,
            base64Data: encodeURIComponent(chunk),
            contentType: file.type,
            fileId: attachId,
            description: description?description:''
        });

        var self = this;
        action.setCallback(this, function(a) {
            if (a.getState() === 'SUCCESS') {
                attachId = a.getReturnValue();
                fromPos = toPos;
                toPos = Math.min(fileContents.length, fromPos + self.CHUNK_SIZE);
                if (fromPos < toPos) {
            	    self.uploadChunk(component, file, fileContents, parentId, fromPos, toPos, attachId, resolveCallback);
                } else {
                    resolveCallback();
                }
            } else if (a.getState() === 'ERROR')   {
                rejectCallback();
            }
        });

        $A.enqueueAction(action);
    },

    checkValue : function(str, max) {
      if (str.charAt(0) !== '0' || str == '00') {
        var num = parseInt(str);
        if (isNaN(num) || num <= 0 || num > max) {
            num = 1;
        }
        str = num > parseInt(max.toString().charAt(0)) && num.toString().length == 1 ? '0' + num : num.toString();
      };
      return str;
    } ,

    disableButton : function(component, buttonId, replacementText) {
        var button = component.find(buttonId);
        button.set("v.disabled", true);
        button.set("v.label", replacementText);
    },

    enableButton : function(component, buttonId, text) {
        var button = component.find(buttonId);
        button.set("v.disabled", false);
        button.set("v.label", text);
    },

    logError : function(className, methodName, errorMessage, developerInfo) {
        var appEvent = $A.get("e.c:ApexCallbackError");
        appEvent.setParams({
            "className" : className,
            "methodName" : methodName,
            "errors" : errorMessage,
            "developerInfo" : developerInfo,
            "stacktrace" : this.getStackTrace()
        });
        appEvent.fire();
    },

    // Options allows the error to be just logged to the database or just displayed to the user
    raiseError : function(className, methodName, errorMessage, developerInfo, options) {
        var appEvent = $A.get("e.c:ApexCallbackError");
        appEvent.setParams({"className" : className,
            "methodName" : methodName,
            "errors" : errorMessage,
            "developerInfo" : developerInfo,
            "options" : options,
            "stacktrace" : this.getStackTrace()
        });
        appEvent.fire();
    },

    //setSearchableValues sets the component's searchable attribute with map of lists all of which hold each text field queried on the record.
    //this makes it easier to search through as the system only has to check if each value in the map holds the text, if so, return the keyValue.
    setSearchableValues : function(component, event, helper, recordsAttribute, originalRecordsAttribute, searchableValuesAttribute, runSetSearchable) {
        if (runSetSearchable) {
            var i;
            var j;
            var l;
            var m;
            var searchObject = {};
            var records = component.get("v." + recordsAttribute);
            component.set("v." + originalRecordsAttribute, records);
            for (i=0; i<records.length;i++) {
                var stringList = [];
                var record = records[i];
                var fieldList = Object.keys(record);
                for (j=0; j<fieldList.length;j++) {
                    var field = fieldList[j];
                    if (field.includes("__r")) {
                        if (record[field] != null) {
                            if (record[field][0] != null) {
                                var childCrossFieldArray = record[field][0];
                            } else {
                                var childCrossFieldArray = record[field];
                            }
                            var childCrossFieldKeys = Object.keys(childCrossFieldArray);
                            for (l=0;l<childCrossFieldKeys.length;l++) {
                                if (record[field].length > 0) {
                                    for (m=0;m<record[field].length;m++) {
                                        var childCrossFieldValue = record[field][m][childCrossFieldKeys[l]];
                                    }
                                } else {
                                    var childCrossFieldValue = record[field][childCrossFieldKeys[l]];
                                }
                                if (typeof childCrossFieldValue === "string") {
                                    if (record.Id in searchObject) {
                                        searchObject[record.Id].push(childCrossFieldValue);
                                    } else {
                                        stringList.push(childCrossFieldValue);
                                        searchObject[record.Id] = stringList;
                                    }
                                } else if (typeof childCrossFieldValue === "number") {
                                    var numberString = childCrossFieldValue.toString();
                                    if (record.Id in searchObject) {
                                        searchObject[record.Id].push(numberString);;
                                    } else {
                                        stringList.push(numberString);
                                        searchObject[record.Id] = stringList;
                                    }
                                }
                            }
                        }
                    } else if (record[field] != null) {
                        var fieldValue = record[field];
                        if (typeof fieldValue === "string") {
                            if (record.Id in searchObject) {
                                searchObject[record.Id].push(fieldValue);
                            } else {
                                stringList.push(fieldValue);
                                searchObject[record.Id] = stringList;
                            }
                        } else if (typeof fieldValue === "number") {
                            var numberString = fieldValue.toString();
                            if (record.Id in searchObject) {
                                searchObject[record.Id].push(numberString);;
                            } else {
                                stringList.push(numberString);
                                searchObject[record.Id] = stringList;
                            }
                        }
                    }
                }
            }
            component.set("v." + searchableValuesAttribute, searchObject);
        }
    },

    executeSearch : function(component, event, helper, searchText, recordsAttribute, originalRecordsAttribute, searchableListAttribute) {
        var originalRecords = component.get("v." + originalRecordsAttribute);
        component.set("v." + recordsAttribute, originalRecords);
        var records = component.get("v." + recordsAttribute);
        var searchableList = component.get("v." + searchableListAttribute);
        var noSearchResult = -1;
        var resultList = [];
        var i;
        var j;
        if (records != null && records.length > 0) {
            for (i=0; i<records.length; i++) {
                var record = records[i];
                if (record.Id in searchableList) {
                    var valueList = searchableList[record.Id];
                    for (j=0; j<valueList.length; j++) {
                        var fieldValueUpperCase = valueList[j].toUpperCase();
                        var searchTextUpperCase = searchText.toUpperCase();
                        if (fieldValueUpperCase.search(searchTextUpperCase) != noSearchResult) {
                            if (resultList.indexOf(record) > -1) {
                                continue;
                            } else {
                                resultList.push(record);
                            }
                        }
                    }
                }
            }
            if (resultList != null && resultList.length > 0) {
                component.set("v." + recordsAttribute, resultList);
                return true;
            } else {
                return false;
            }
        }
    },

    startSpinner : function(component, name) {
        var spinner = component.find(name);
        var evt = spinner.get("e.toggle");
        evt.setParams({ isVisible : true });
        evt.fire();
    },

    stopSpinner : function(component, spinnerName) {
        var spinner = component.find(spinnerName);
        var evt = spinner.get("e.toggle");
        evt.setParams({ isVisible : false });
        evt.fire();
    },

    closeModal : function(component, modalId) {
        var modal = component.find(modalId);
        $A.util.removeClass(modal, 'slds-fade-in-open');
        $A.util.addClass(modal, 'slds-fade-in-hide');
    },

    openModal : function(component, modalId) {
        var modal = component.find(modalId);
        $A.util.addClass(modal, 'slds-fade-in-open');
        $A.util.removeClass(modal, 'slds-fade-in-hide');
    },


    // To compare date strings
    getFormattedDate : function(dateString) {
        if (dateString) {
            const dateToFormat = new Date(dateString+'T00:00:00')
            const year = dateToFormat.getFullYear();
            const month = (1 + dateToFormat.getMonth()).toString();
            const day = dateToFormat.getDate().toString();
            return (month.length>1?month:'0'+month) + '/' + (day.length>1?day:'0'+day) + '/' + year;
        } else {
            return '';
        }

    },

    validatePageFields : function(component) {
        var pageFields = component.find('field');
        if (!pageFields) return true;
        var isAllValid = [].concat(pageFields).reduce(function (validSoFar, inputCmp) {
            // showHelpMessageIfInvalid exists for lightning:input, but not ui:input
            if (typeof inputCmp.showHelpMessageIfInvalid === 'function') {
                inputCmp.showHelpMessageIfInvalid();
                return validSoFar && inputCmp.get('v.validity').valid;
            } else {
                return true;
            }
            }, true
        );
        return isAllValid;
    },

    showToast : function(component, title, message) {
        component.find('notifLib').showToast({
            "title": title,
            "message": message
        });
    },

    showNotice : function(component, callback, header, message, callbackParams) {
        component.find('notifLib').showNotice({
            "variant": "error",
            "header": header,
            "message": message,
            closeCallback: function() {
                callback(callbackParams)
            }
        });
    },

    openBoxUploader : function (description) {
        let title = 'Submit%20Documentation%20to%20BlueWave';
        let instructions = 'Please include "' + description + '" in the File Description';
        let link = "https://bluewave-capital.app.box.com/upload-widget/preview?folderID=52259130943&title=";
        link += title;
        link += "&instructions=" + instructions.replace(' ', "%20");
        link += "&isDescriptionFieldShown=1&isEmailRequired=1&width=385&height=420&token=nzwxuyckgi5aqvj6dhg2ppn1ws6y1n6s"
        window.open(link);
    },

    // Per https://stackoverflow.com/a/28118170
    getStackTrace : function() {
        let stack;
        try {
            // noinspection ExceptionCaughtLocallyJS
            throw new Error('');
        } catch (error) {
            stack = error.stack || '';
        }
        stack = stack.split('\n').map(function (line) { return line.trim(); });
        return stack.splice(stack[0] === 'Error' ? 2 : 1).join('\n');
    }
})