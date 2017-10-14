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

    getDataFromServer : function(component, methodName, setAttribute) {
        var action = component.get("c." + methodName);        
        action.setCallback(this,function(resp){ 
            if(resp.getState() == 'SUCCESS') {
                for (var i=0; i<setAttribute.length; i++) {
                    component.set("v." + setAttribute[i], resp.getReturnValue());
                }
            }
            else {
                $A.log("Errors", resp.getError());
            }
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
                    appEvent.setParams({"className" : "BlueWaveParentHelper",
                                        "methodName" : "updateSObject",
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

    insertSObject : function(component, sObject) {
        return new Promise(function(resolve, reject) {
            var action = component.get("c.insertSObject");
            action.setParams({"sobj": sObject});
            action.setCallback(this, function(resp) {
                if (resp.getState() === "SUCCESS") {
                    var retVal = resp.getReturnValue();
                    resolve(retVal);
                } else if (resp.getState() === "ERROR") {
                    var appEvent = $A.get("e.c:ApexCallbackError");
                    appEvent.setParams({"className" : "BlueWaveParentHelper",
                                        "methodName" : "insertSObject",
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

    logError : function(className, methodName, errorMessage) {
        var appEvent = $A.get("e.c:ApexCallbackError");
        appEvent.setParams({"className" : className,
                            "methodName" : methodName,
                            "errors" : errorMessage});
        appEvent.fire();
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
})

