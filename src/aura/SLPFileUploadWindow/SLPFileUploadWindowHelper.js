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
        var MAXFILE_SIZE = 4500000;
        var CHUNKFILE_SIZE = 400000; 
      	var fileInput = component.find("file").getElement();
        var file = fileInput.files[0];
        if (file === undefined) {
            component.set("v.errorText", 'Please Select a File');
            this.addErrorMessaging(component);
            return;
        }
        else if (file.size > MAXFILE_SIZE) {
            component.set("v.errorText", 'File size cannot exceed ' + MAXFILE_SIZE + ' bytes.\n' +
              'Selected file size: ' + file.size);
            this.addErrorMessaging(component);
            return;
        } 
        var self = this;
        var fr = component.get("v.fileReader");
        var fileContents = fr.result;
        var base64Mark = 'base64,';
        var dataStart = fileContents.indexOf(base64Mark) + base64Mark.length;
        fileContents = fileContents.substring(dataStart);
        if (file.size > CHUNKFILE_SIZE) {
			  self.startSpinner(component);
              var fromPos = 0;
        	  var toPos = Math.min(fileContents.length, fromPos + CHUNKFILE_SIZE);
              var attachID = 'none';
              self.uploadLargeFile(component, file, fileContents, fileType, parentId, attachID, fromPos, toPos);
        } else {
              self.uploadSmallFile(component, file, fileContents, fileType, parentId);
        }
    },
    
    uploadSmallFile : function(component, file, fileContents, fileType, parentId) {
        var newFileName = component.get("v.fileName");
        var action = component.get("c.saveTheFile");   
        var self = this;
        var descriptionValue = "";
        if (fileType === 'Interconnection Documentation') {
            descriptionValue = 'PTO Documentation';
        } else {
            descriptionValue = fileType;
        }
        action.setParams({
            parentId: parentId,
            fileName: newFileName,
            base64Data: encodeURIComponent(fileContents), 
            contentType: file.type,
            fileType: fileType,
            description : descriptionValue
        }); 
        
        action.setCallback(this,function(resp) {       
          if(resp.getState() == "SUCCESS"){  
              self.fileUploadSuccess(component);
          } else {
			 self.fileUploadError(component);
          }
        });
        $A.enqueueAction(action); 
    },         
        
    uploadLargeFile : function (component, file, fileContents, fileType, parentId, attachID, fromPos, toPos) {
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
            } else {
           		$A.util.addClass(component.find("spinner"), 'noDisplay'); 
                self.fileUploadSuccess(component);
            }
          } else {
              self.fileUploadError(component);
          }
        });
        $A.enqueueAction(action); 
    },
    
    startSpinner : function (component) {
       $A.util.removeClass(component.find("spinner"), 'noDisplay'); 
       $A.util.addClass(component.find("uploadButton"), 'noDisplay'); 
       $A.util.addClass(component.find("inputDate"), 'noDisplay'); 
    },
      
    fileUploadSuccess : function (component) {
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
       $A.util.addClass(component.find("windowBody"), 'noDisplay');
       $A.util.addClass(component.find("headerText"), 'noDisplay'); 
    },       
  
  	closeWindow : function(component) {
        $A.util.removeClass(component.find("greyout"), 'slds-backdrop_open'); 
        $A.util.addClass(component.find("greyout"), 'slds-backdrop_hide');  
        $A.util.removeClass(component.find("smallWindow"), 'slds-fade-in-open'); 
        $A.util.addClass(component.find("smallWindow"), 'slds-fade-in-hide');  
    },
    
    greyOutUpload : function(component) {
        $A.util.removeClass(component.find("uploadButton"), 'blueBackground'); 
        $A.util.addClass(component.find("uploadButton"), 'greyBackground'); 
        $A.util.removeClass(component.find("uploadIcon"), 'border'); 
        $A.util.addClass(component.find("uploadIcon"), 'greyborder'); 
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
})