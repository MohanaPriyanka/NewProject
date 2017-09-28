({  checkDateField : function(component, helper, dateValue) {
        var errorMessage = "";
        if (helper.invalidField(component, dateValue, null, false, false, false, "date")) {
            $A.util.addClass(component.find("inputDate"), 'shake slds-has-error'); 
            errorMessage = "Please enter a date in the format MM/DD/YYYY." + "\n" + "\n";
        } 
        return errorMessage;
    },
  
  	saveFileToList : function(component) {
    	var self = this;
        self.removeErrorMessaging(component);
        self.greyOutSelection(component);
        var fileInput = component.find("file").getElement();
     	var numberOfFiles = fileInput.files.length; 
     	var MAXFILE_SIZE = 4500000;
     	var fileStep;
        for (fileStep = 0; fileStep < numberOfFiles; fileStep++) {
       	    var file = fileInput.files[fileStep];
            if (file === undefined) {
                component.set("v.errorText", 'Please Select a File');
                self.addErrorMessaging(component);
                return;
            }
            else if (file.size > MAXFILE_SIZE) {
                component.set("v.errorText", 'File size cannot exceed ' + MAXFILE_SIZE + ' bytes.\n' +
                  'Selected file size: ' + file.size);
                self.addErrorMessaging(component);
                return;
            }
            var fr = new FileReader();
        	fr.readAsDataURL(file);
			component.get("v.fileReader").push(fr);
            component.get("v.fileList").push(file);
      	}
        var newFileList = component.get("v.fileList");
        component.set("v.fileList", newFileList);
        var numberOpen = newFileList.length;
        if (numberOpen === 4) {
           $A.util.addClass(component.find("fileUploadBox"), 'noDisplay'); 
           return;        	
        } 
  	},
  
  	removeFileFromList : function(component, fileToRemove) {
        var newList= component.get("v.fileList");
        var newListReader = component.get("v.fileReader");
        var numberOfFiles = newList.length; 
        var fileStep;
        for (fileStep = 0; fileStep < numberOfFiles; fileStep++) {
            var file = newList[fileStep];
            if (file.name === fileToRemove) {
                var toDeleteLocation = fileStep;
                $A.util.removeClass(component.find("fileUploadBox"), 'noDisplay'); 
            } 
        }
        newList.splice(toDeleteLocation, 1);
        newListReader.splice(toDeleteLocation, 1);
        component.set("v.fileList", newList);
        component.set("v.fileReader", newListReader);
  	},

    saveFilesToServer : function(component, event, parentId, fileStep, fileInput, newFileName, fr, numberOfFiles, helper) {
   		$A.util.addClass(component.find("saveButton"), 'noDisplay');
        var self = this;
        var CHUNKFILE_SIZE = 400000; 
        if (fileInput === undefined || fileInput.length === 0 ) {
            component.set("v.errorText", 'Please Select a File');
            self.addErrorMessaging(component);
            return;
        }
        self.startSpinner(component);
        var file = fileInput[fileStep];
        var fileContents = fr[fileStep].result;
        var base64Mark = 'base64,';
        var dataStart = fileContents.indexOf(base64Mark) + base64Mark.length;
        fileContents = fileContents.substring(dataStart);
        var fromPos = 0;
        var toPos = Math.min(fileContents.length, fromPos + CHUNKFILE_SIZE);
        var attachID = 'none';
        var fileStepPlusOne = fileStep + 1;
        var fileUploadPromise = self.uploadChunk(component, newFileName, file, fileContents, parentId, attachID, fromPos, toPos, fileStepPlusOne, numberOfFiles);
       	fileUploadPromise.then(
            $A.getCallback(function(result) {
                console.log(result);
                self.handlePromiseResult(component, result, fileInput, fr, newFileName, file, fileContents, parentId, attachID, fromPos, toPos, fileStepPlusOne, numberOfFiles, helper);
            }),
            $A.getCallback(function() {
	        	component.set("v.errorText", 'There was an Error Uploading your Document.');
                self.addErrorMessaging(component);
                return;
	        })
        );
    },    

    handlePromiseResult : function (component, result, fileInput, fr, newFileName, file, fileContents, parentId, attachID, fromPos, toPos, fileStep, numberOfFiles, helper) {
	    console.log(result);
	    var self = this;
	    if (result === 'continueToNextFile' ) {
	        self.saveFilesToServer(component, event, parentId, fileStep, fileInput, newFileName, fr, numberOfFiles);
	    } else if (result === 'lastFileCompleted' ) {
			self.fileUploadSuccess(component, parentId, newFileName, helper);
	    } else if (result != undefined) {
	        var arrayVariables = result.split(", ", 3);
	        var chunkPromise = self.uploadChunk(component, newFileName, file, fileContents, parentId, arrayVariables[0], Number(arrayVariables[1]),  Number(arrayVariables[2]), fileStep, numberOfFiles);
	        chunkPromise.then(
	        	$A.getCallback(function(resultUpdated) {
	        		self.handlePromiseResult(component, resultUpdated, fileInput, fr, newFileName, file, fileContents, parentId, attachID, fromPos, toPos, fileStep, numberOfFiles, helper); 	
	        	}) ,
	        	$A.getCallback(function() {
	        		component.set("v.errorText", 'There was an Error Uploading your Document.');
                	self.addErrorMessaging(component);
                	return;
	        	})
	        );
	    }
	},
        
    uploadChunk : function (component, newFileName, file, fileContents, parentId, attachID, fromPos, toPos, fileStep, numberOfFiles) {
        return new Promise(function(resolve, reject) {
            var CHUNKFILE_SIZE = 400000; 
            var action = component.get("c.saveTheChunk"); 
            var chunk = fileContents.substring(fromPos, toPos);
            var descriptionValue = file.name;
            if (newFileName === 'Interconnection Documentation') {
                descriptionValue = 'PTO Documentation';
            } else {
                descriptionValue = newFileName;
            }
            action.setParams({
    			parentId: parentId,
                fileName: newFileName,
                base64Data: encodeURIComponent(chunk), 
                contentType: file.type,
                fileType: newFileName,
                description: descriptionValue,
                fileId : attachID,
            });
            var self = this;
            action.setCallback(this, function(a) {
                if(a.getState() == "SUCCESS"){ 
                    attachID = a.getReturnValue();
                    fromPos = toPos;
                    toPos = Math.min(fileContents.length, fromPos + CHUNKFILE_SIZE); 
                    var newString = attachID.concat(', ',fromPos,', ',toPos);  
                    if (fromPos < toPos) {
                	   resolve(newString);
                    } else if (fileStep === numberOfFiles) {
                        resolve('lastFileCompleted');
                    } else {
                        resolve('continueToNextFile');
                    }
                } else {
                    reject('error');
                }
            });
            $A.enqueueAction(action); 
        });
    },
  
    startSpinner : function (component) {
        $A.util.removeClass(component.find("spinner"), 'noDisplay'); 
        $A.util.addClass(component.find("helpTextLine"), 'noDisplay'); 
        $A.util.addClass(component.find("uploadButton"), 'noDisplay'); 
        $A.util.addClass(component.find("inputDate"), 'noDisplay'); 
        $A.util.addClass(component.find("greyBoxes"), 'noDisplay'); 
        $A.util.addClass(component.find("fileTypePicklist"), 'noDisplay'); 
    },
      
    fileUploadSuccess : function (component, parentId, fileName, helper) {
        $A.util.addClass(component.find("spinner"), 'noDisplay'); 
        var self = this;
        var newDate = component.get("v.dateValue");
        var oppId = component.get("v.oppId");

        if (fileName === 'Mechanical Installation Documentation') {
            var mechDate = self.saveObject(component, parentId, 'Residential_Equipment__c', 'Mechanical_Installation_Date__c', newDate);
            mechDate.then(
                $A.getCallback(function(result) {
                    var mechCheck = self.saveObject(component, parentId, 'Residential_Equipment__c', 'Mechanically_Installed__c', true);
                })
            )
            if (oppId != undefined || oppId != NULL) {
                var oppMechDate = self.saveObject(component, oppId, 'Opportunity', 'Mechanical_Install_Date_From_RE__c', newDate);
                oppMechDate.then(
                    $A.getCallback(function(result) {
                        var oppMechCheck = self.saveObject(component, oppId, 'Opportunity', 'Mechanically_Installed__c', true);
                    })
                )
            }
        } else if (fileName === 'Interconnection Documentation') {
            var interDate = self.saveObject(component, parentId, 'Residential_Equipment__c', 'Interconnection_Date__c', newDate);
            interDate.then(
                $A.getCallback(function(result) {
                    console.log(interDate);
                    var interCheck = self.saveObject(component, parentId, 'Residential_Equipment__c', 'Interconnected__c', true);
                })
            )
            if (oppId != undefined || oppId != NULL) {
                var oppInterDate = self.saveObject(component, oppId, 'Opportunity', 'Interconnection_Date_From_RE__c', newDate);
                oppInterDate.then(
                    $A.getCallback(function(result) {
                        var oppInterCheck = self.saveObject(component, oppId, 'Opportunity', 'Interconnected__c', true);
                    })
                )
            } 
        } else if (fileName === 'Sales Agreement') {
            var salesCheck = self.saveObject(component, parentId, 'Opportunity', 'Partner_Sales_Agreement_Status__c', 'Completed');
            salesCheck.then(
                $A.getCallback(function(result) {
                    var salesDummy = self.saveObject(component, parentId, 'Opportunity', 'Update_Dummy__c', true);
                })
            )
        } else if (fileName === 'MCEC Technical Confirmation') { 
            if (parentId.substring(0,3) === '00Q') {
                var techConfirm = self.saveObject(component, parentId, 'Lead', 'Update_Dummy__c', true);
            }
        } else if (fileName === 'Home Owners Insurance') {
            var homeOwners = self.saveObject(component, parentId, 'Opportunity', 'Homeowner_s_Insurance_Status__c', 'Received: in QC');
        }

        $A.util.removeClass(component.find("successText"), 'noDisplay'); 
        $A.util.removeClass(component.find("doneButton"), 'noDisplay'); 
        $A.util.addClass(component.find("windowBody"), 'noDisplay'); 
        $A.util.addClass(component.find("headerText"), 'noDisplay'); 
        $A.util.addClass(component.find("saveButton"), 'noDisplay'); 
        $A.util.addClass(component.find("closeButton"), 'noDisplay'); 
    },

  	// this is the exact same as the BlueWave Parent - ideally this section will be removed. 
    saveObject : function(component, id, objectName, field, value) {
      return new Promise(function(resolve, reject) {
          var sobj = new Object();
          sobj = {'sobjectType': objectName,
                  'Id': id};
          sobj[field] = value;
          var action = component.get("c.updateSObject");
          action.setParams({"sobj": sobj});
          action.setCallback(this, function(resp) {
              if (resp.getState() === "SUCCESS") {3
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
    
    fileUploadError : function (component) {
        component.set("v.errorText", "There has been an error uploading your document.");
        $A.util.removeClass(component.find("errorTextLine"), 'noDisplay'); 
        $A.util.addClass(component.find("spinner"), 'noDisplay');
        $A.util.addClass(component.find("headerText"), 'noDisplay'); 
    },       
  
  	closeWindow : function(component) {
        $A.util.removeClass(component.find("greyout"), 'slds-backdrop_open'); 
        $A.util.addClass(component.find("greyout"), 'slds-backdrop_hide');  
        $A.util.removeClass(component.find("smallWindow"), 'slds-fade-in-open'); 
        $A.util.addClass(component.find("smallWindow"), 'slds-fade-in-hide');  
    },
    
    greyOutSelection : function(component) {
        if (component.get("v.dateLabel") === 'hideAndFileOption') {
            component.find("inputFileType").set("v.disabled","true");
        }
    },
    
    addErrorMessaging : function(component) {
	    $A.util.removeClass(component.find("errorTextLine"), 'noDisplay'); 
        $A.util.addClass(component.find("uploadButton"), 'shake'); 
        $A.util.removeClass(component.find("saveButton"), 'noDisplay');
    },
    
    removeErrorMessaging : function(component) {
		$A.util.addClass(component.find("errorTextLine"), 'noDisplay');
        $A.util.removeClass(component.find("inputDate"), 'shake slds-has-error'); 
    },
  
    firePartnerTaskRefresh : function(component, helper) {
	 	var evtCustomerPage = $A.get("e.c:SLPafterFileUpload");
        evtCustomerPage.fire(); 
        helper.closeWindow(component);
    },
})