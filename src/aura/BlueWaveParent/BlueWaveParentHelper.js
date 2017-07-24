({
    getPicklistOptions : function(component, objectName, fieldName, inputSelect) {
        var action = component.get("c.getPicklistFields");
        action.setParams({"objectName": objectName,
                          "fieldName": fieldName});
        action.setStorable();
        var opts=[];
        action.setCallback(this, function(a) {
            for(var i=0;i< a.getReturnValue().length;i++){
                opts.push({"class": "optionClass", label: a.getReturnValue()[i], value: a.getReturnValue()[i]});
            }
            inputSelect.set("v.options", opts);
        });
        $A.enqueueAction(action); 
    },

    saveSObject : function(component, id, objectName, field, value) {
        return new Promise(function(resolve, reject) {
            var sobj = new Object();
            sobj = {'sobjectType': objectName,
                    'Id': id};
            sobj[field] = value;
            var action = component.get("c.updateSObject");
            action.setParams({"sobj": sobj});
            action.setCallback(this, function(resp) {
                if (resp.getState() === "SUCCESS") {
                    var retVal = resp.getReturnValue();
                    resolve(retVal);
                } else if (resp.getState() === "ERROR") {
                    var appEvent = $A.get("e.c:ApexCallbackError");
                    appEvent.setParams({"className" : "LoanUnderwritingController",
                                        "methodName" : "updateReviewStatus",
                                        "errors" : resp.getError()});
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
    /* 
       CHUNK_SIZE: Use a multiple of 4. 950000 in the blog post didn't work, 
       81250 works except for one test file, 40000 seems to work ok...
    */
    // http://peterknolle.com/file-upload-lightning-component/
    // Assumes callbackFunc takes a component as an argument - not sure if that will always work...
    uploadFiles : function(component, files, parentId, callbackFunc) {
        ltg = this;
        for (var i=0; i<files.length; i=i+1) {
            (function(file) {
                if (file.size > ltg.MAX_FILE_SIZE) {
                    alert('File size cannot exceed ' + ltg.MAX_FILE_SIZE + ' bytes.\n' +
    	                  'Selected file size: ' + file.size + '\n' +
                          'Please use the standard Attachment Upload instead');
                    return;
                }
                var fr = new FileReader(); 

       	        fr.onload = function() {
                    var fileContents = fr.result;
                    var base64Mark = 'base64,';
                    var dataStart = fileContents.indexOf(base64Mark) + base64Mark.length;

                    fileContents = fileContents.substring(dataStart);
                    
                    ltg.upload(component, file, fileContents, parentId).then(
                        $A.getCallback(function resolve() {
                            if (callbackFunc) {
                                callbackFunc(component);
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
    
    upload: function(component, file, fileContents, parentId) {
        var fromPos = 0;
        var toPos = Math.min(fileContents.length, fromPos + this.CHUNK_SIZE);
	
        // start with the initial chunk
        var ltg = this;
        return new Promise($A.getCallback(function(resolve, reject) {
            ltg.uploadChunk(component, file, fileContents, parentId, fromPos, toPos, '', resolve, reject);
        }));
    },
    
    uploadChunk : function(component, file, fileContents, parentId, fromPos, toPos, attachId, resolveCallback, rejectCallback) {
        console.log('uploadChunk fromPos: ' + fromPos + ' toPos: ' + toPos + ' of: ' + fileContents.length);
        var action = component.get("c.saveTheChunk"); 
        var chunk = fileContents.substring(fromPos, toPos);

        action.setParams({
            parentId: parentId,
            fileName: file.name,
            base64Data: encodeURIComponent(chunk), 
            contentType: file.type,
            fileId: attachId
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
        if (isNaN(num) || num <= 0 || num > max) num = 1;
        str = num > parseInt(max.toString().charAt(0)) && num.toString().length == 1 ? '0' + num : num.toString();
      };
      return str;
    } ,

    // For some reason, using this pattern in a lighting:input type=date doesn't work
    // Assumes dateString comes from ui:inputDate, which uses format yyyy-mm-dd
    // only validates format xxxx-xx-xx, but we can add checks for numbers, leap years,
    // etc.
    // See http://stackoverflow.com/questions/6177975/how-to-validate-date-with-format-mm-dd-yyyy-in-javascript
    validDate : function(dateString) {
        // First check for the pattern
        var format = /^\d{2}\/\d{2}\/\d{4}$/;
        return format.test(dateString);
    } ,

    validEmail : function(emailString) {
        var re = /^(([^<>()\[\]\\.,;:\s@"]+(\.[^<>()\[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;
        return re.test(emailString);
    } ,

    validSSN : function(ssnString) {
        if (ssnString.length == 9) {
            return true;
        } else {
            return false;
        }
    } ,

    validZipCode : function(zipCode) {
        if (zipCode.length == 5) {
            return true;
        } else {
            return false;
        }
    }                    
})

