({  checkDateField : function(component, helper, dateValue) {
        var errorMessage = "";
        if (helper.invalidField(component, dateValue, null, false, false, false, "date")) {
            $A.util.addClass(component.find("inputDate"), 'shake slds-has-error'); 
            errorMessage = "Please enter a date in the format MM/DD/YYYY." + "\n" + "\n";
        }
        return errorMessage;
    },
        
    saveFile : function(component, event, fileType, parentId) {
        $A.util.addClass(component.find("saveButton"), 'noDisplay');
        var self = this;
        var MAXFILE_SIZE = 4500000;
        var CHUNKFILE_SIZE = 400000; 
      	var fileInput = component.get("v.fileList");
        if (fileInput === undefined || fileInput.length === 0 ) {
             component.set("v.errorText", 'Please Select a File');
             self.addErrorMessaging(component);
             return;
        }
        var fr = component.get("v.fileReader");
        var numberOfFiles = fr.length; 
        self.startSpinner(component);
        var fileStep;
        console.log(fileInput);
        console.log(fr);
		for (fileStep = 0; fileStep < numberOfFiles; fileStep++) {
            var file = fileInput[fileStep];
            var fileContents = fr[fileStep].result;
            var base64Mark = 'base64,';
            var dataStart = fileContents.indexOf(base64Mark) + base64Mark.length;
            fileContents = fileContents.substring(dataStart);
            var fromPos = 0;
            var toPos = Math.min(fileContents.length, fromPos + CHUNKFILE_SIZE);
            var attachID = 'none';
            var fileStepPlusOne = fileStep + 1;
            self.uploadLargeFile(component, file, fileContents, fileType, parentId, attachID, fromPos, toPos, fileStepPlusOne, numberOfFiles);
        }
    },    
        
    uploadLargeFile : function (component, file, fileContents, fileType, parentId, attachID, fromPos, toPos, fileStep, numberOfFiles) {
        var newFileName = component.get("v.fileName");
        var CHUNKFILE_SIZE = 400000; 
        var action = component.get("c.saveTheChunk"); 
        var chunk = fileContents.substring(fromPos, toPos);
        var descriptionValue = file.name ;
        if (fileType === 'Interconnection Documentation') {
            descriptionValue = 'PTO Documentation';
        } else {
            descriptionValue = fileType;
        }
        action.setParams({
			parentId: parentId,
            fileName: newFileName,
            base64Data: encodeURIComponent(chunk), 
            contentType: file.type,
            fileType: fileType,
            description: descriptionValue,
            fileId : attachID,
        });
        var self = this;
        action.setCallback(this, function(a) {
          if(a.getState() == "SUCCESS"){ 
            attachID = a.getReturnValue();
            fromPos = toPos;
            toPos = Math.min(fileContents.length, fromPos + CHUNKFILE_SIZE);    
            if (fromPos < toPos) {
            	self.uploadLargeFile(component, file, fileContents, fileType, parentId, attachID, fromPos, toPos);  
            } else if (fileStep === numberOfFiles) {
           		$A.util.addClass(component.find("spinner"), 'noDisplay'); 
                self.fileUploadSuccess(component, parentId, newFileName);
            }
          } else {
              self.fileUploadError(component);
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
      
    fileUploadSuccess : function (component, parentId, fileName) {
       var self = this;
       var newDate = component.get("v.dateValue");
       if (fileName === 'Mechanical Installation Documentation') {
            var mechDate = self.saveObject(component, parentId, 'Residential_Equipment__c', 'Mechanical_Installation_Date__c', newDate);
            mechDate.then(
                $A.getCallback(function(result) {
                    var mechCheck = self.saveObject(component, parentId, 'Residential_Equipment__c', 'Mechanically_Installed__c', true);
                })
            )
       } else if (fileName === 'Interconnection Documentation') {
            var interDate = self.saveObject(component, parentId, 'Residential_Equipment__c', 'Interconnection_Date__c', newDate);
            interDate.then(
                $A.getCallback(function(result) {
                    var interCheck = self.saveObject(component, parentId, 'Residential_Equipment__c', 'Interconnected__c', true);
                })
            )
       } else if (fileName === 'Sales Agreement') {
            var salesCheck = self.saveObject(component, parentId, 'Opportunity', 'Partner_Sales_Agreement_Status__c', 'Completed');
            salesCheck.then(
                $A.getCallback(function(result) {
                    var salesDummy = self.saveObject(component, parentId, 'Opportunity', 'Update_Dummy__c', true);
                })
            )
       } else if (fileName === 'MCEC Technical Confirmation') {
         	console.log("MCEC");
       } else if (fileName === 'Home Owners Insurance') {
         	console.log("Insurance");
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
        component.find("inputFileType").set("v.disabled","true");
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