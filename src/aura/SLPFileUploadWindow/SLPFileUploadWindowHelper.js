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
        var fileInput = component.find("file").getElement();
     	var numberOfFiles = fileInput.files.length; 
     	var MAXFILE_SIZE = 4500000;
     	var fileStep;
        for (fileStep = 0; fileStep < numberOfFiles; fileStep++) {
       	    var file = fileInput.files[fileStep];
            if (file === undefined || component.get("v.fileName") == 'Select File Type') {
                component.set("v.errorText", 'Please Select a File Type');
                self.addErrorMessaging(component);
                return;
            } else if (file.size > MAXFILE_SIZE) {
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
        self.greyOutSelection(component);
        var newFileList = component.get("v.fileList");
        component.set("v.fileList", newFileList);
        var numberOpen = newFileList.length;
        if (numberOpen === 4) {
           $A.util.addClass(component.find("fileUploadBox"), 'noDisplay'); 
           return;        	
        } 
  	},
  
  	removeFileFromList : function(component, fileToRemove) {
        var self = this;
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
        var newFileList = component.get("v.fileList");
        if(newFileList === undefined || newFileList.length === 0){
           self.unGreyOutSelection(component);       
        } 
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
        var attachID = '';
        var fileStepPlusOne = fileStep + 1;
        var fileUploadPromise = self.uploadChunk(component, newFileName, file, fileContents, parentId, attachID, fromPos, toPos, fileStepPlusOne, numberOfFiles);
       	fileUploadPromise.then(
            $A.getCallback(function(result) {
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
	    var self = this;
	    if (result === 'continueToNextFile' ) {
	        self.saveFilesToServer(component, event, parentId, fileStep, fileInput, newFileName, fr, numberOfFiles, helper);
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
            var action = component.get("c.saveTheChunkWithDescription"); 
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
                emailNotification: 'solarloans@bluewavesolar.com',
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

    addDisbursalOnHoldMessage : function(component, parentId, oppId) {
        var action = component.get("c.checkIfDisbursalOnHold");
        var self = this;
        action.setParams({
            oppId: oppId
        });
        action.setCallback(this, function(a) {
            if(a.getState() == "SUCCESS") {
                var isDisbursalOnHold = a.getReturnValue();
                if (isDisbursalOnHold) {
                    component.set("v.disbursalMessage", 'A disbursal for this job is on hold. Please contact BlueWave Partner Support at partnersupport@bluewavesolar.com or 888-817-2703 for more details.');
                    return;
                }
            }
        });
        $A.enqueueAction(action);
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
        var newDate = component.get("v.dateValue");
        var oppId = component.get("v.oppId");
        let leadId = component.get('v.leadId');
        var self = this;
        var actionOne;
        var actionTwo;
        var actionThree;
        var actionFour;

        // if the file type needs something specific, do it here, otherwise update the update dummy
        if (fileName === 'Mechanical Installation Documentation') {
            actionOne = helper.saveSObjectErrorOption(component, parentId, 'Residential_Equipment__c', 'Mechanical_Installation_Date__c', newDate, null, {suppressAlert: true});
            actionTwo = helper.saveSObjectErrorOption(component, parentId, 'Residential_Equipment__c', 'Mechanically_Installed__c', true, null, {suppressAlert: true});
            if (oppId != undefined || oppId != NULL) {
                actionThree = helper.saveSObjectErrorOption(component, oppId, 'Opportunity', 'Mechanical_Install_Date_From_RE__c', newDate, null, {suppressAlert: true});
                actionFour = helper.saveSObjectErrorOption(component, oppId, 'Opportunity', 'Mechanically_Installed__c', true, null, {suppressAlert: true});
            }
            self.addDisbursalOnHoldMessage(component, parentId, oppId);
        } else if (fileName === 'Interconnection Documentation') {
            actionOne = helper.saveSObjectErrorOption(component, parentId, 'Residential_Equipment__c', 'Interconnection_Date__c', newDate, null, {suppressAlert: true});
            actionTwo = helper.saveSObjectErrorOption(component, parentId, 'Residential_Equipment__c', 'Interconnected__c', true,  null, {suppressAlert: true});
            if (oppId != undefined || oppId != NULL) {
                actionThree = helper.saveSObjectErrorOption(component, oppId, 'Opportunity', 'Interconnection_Date_From_RE__c', newDate,  null, {suppressAlert: true});
                actionFour = helper.saveSObjectErrorOption(component, oppId, 'Opportunity', 'Interconnected__c', true,  null, {suppressAlert: true});
            }
            self.addDisbursalOnHoldMessage(component, parentId, oppId);
        } else if (fileName === 'Sales Agreement') {
            if (oppId != undefined || oppId != NULL) {
                actionOne = helper.saveSObjectErrorOption(component, parentId, 'Opportunity', 'Partner_Sales_Agreement_Status__c', 'Completed',  null, {suppressAlert: true});
                actionTwo = helper.saveSObjectErrorOption(component, parentId, 'Opportunity', 'Update_Dummy__c', true,  null, {suppressAlert: true});
                actionThree = helper.saveSObjectErrorOption(component, parentId, 'Opportunity', 'Update_Dummy__c', false,  null, {suppressAlert: true});
            } 
        } else if (fileName === 'Home Owners Insurance') {
            if (oppId != undefined || oppId != NULL) {
                actionOne = helper.saveSObjectErrorOption(component, parentId, 'Opportunity', 'Homeowner_s_Insurance_Status__c', 'Received: in QC',  null, {suppressAlert: true});
            } 
        } else { 
            if (parentId.substring(0,3) === '00Q') {
                actionOne = helper.saveSObjectErrorOption(component, parentId, 'Lead', 'Update_Dummy__c', true,  null, {suppressAlert: true});
                actionTwo = helper.saveSObjectErrorOption(component, parentId, 'Lead', 'Update_Dummy__c', false,  null, {suppressAlert: true});
            } else if (parentId.substring(0,3) === '003') {
                actionOne = helper.saveSObjectErrorOption(component, leadId, 'Lead', 'Update_Dummy__c', true,  null, {suppressAlert: true});
                actionTwo = helper.saveSObjectErrorOption(component, leadId, 'Lead', 'Update_Dummy__c', false,  null, {suppressAlert: true});
            } else if (oppId != undefined || oppId != NULL) {
                actionOne = helper.saveSObjectErrorOption(component, parentId, 'Opportunity', 'Update_Dummy__c', true,  null, {suppressAlert: true});
                actionTwo = helper.saveSObjectErrorOption(component, parentId, 'Opportunity', 'Update_Dummy__c', false,  null, {suppressAlert: true});
            } else {
                $A.util.addClass(component.find("spinner"), 'noDisplay'); 
                component.set("v.errorText", 'Error: Not Linked to a Lead or Opp');
                self.addErrorMessaging(component);
                $A.util.addClass(component.find("saveButton"), 'noDisplay'); 
                return;
            }
        } 
        actionOne.then(
            $A.getCallback(function(result) {
                self.postUploadAction(component);
            }) ,
            $A.getCallback(function() {
                self.postUploadAction(component);
                return;
            })
        );
    },

    postUploadAction : function (component) {
        $A.util.addClass(component.find("spinner"), 'noDisplay'); 
        $A.util.removeClass(component.find("successText"), 'noDisplay'); 
        $A.util.removeClass(component.find("doneButton"), 'noDisplay'); 
        $A.util.addClass(component.find("windowBody"), 'noDisplay'); 
        $A.util.addClass(component.find("headerText"), 'noDisplay'); 
        $A.util.addClass(component.find("saveButton"), 'noDisplay'); 
        $A.util.addClass(component.find("closeButton"), 'noDisplay'); 
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

    unGreyOutSelection : function(component) {
        if (component.get("v.dateLabel") === 'hideAndFileOption') {
            component.find("inputFileType").set("v.disabled","false");
        }
    },
    
    addErrorMessaging : function(component) {
        $A.util.removeClass(component.find("errorTextLine"), 'noDisplay'); 
        $A.util.addClass(component.find("uploadButton"), 'shake'); 
        $A.util.removeClass(component.find("saveButton"), 'noDisplay');
        $A.util.addClass(component.find("spinner"), 'noDisplay'); 
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

    getPreviousTaxYear : function() {
        var previousTaxYear;
        var today = new Date();
        var thisYear = today.getFullYear();
        if (today.getMonth() > 3) {
            // return last year if we've past the tax deadline month, (April 15)
            previousTaxYear = thisYear - 1;
        } else {
            // return the year before last if we haven't past the tax deadline
            previousTaxYear = thisYear - 2;
        }
        return previousTaxYear;
    },
})