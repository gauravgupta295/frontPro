({
	init: function (cmp,evt,helper){
        helper.showSpinner(cmp);
        var getDeliveryMethodOptions = cmp.get("c.getDeliveryMethodValues");
        getDeliveryMethodOptions.setCallback(this, function(response){
            var getDeliveryMethodState = response.getState(); 
            if (getDeliveryMethodState === "SUCCESS"){
                var fieldData = response.getReturnValue();
                cmp.set("v.fieldOptions", fieldData);
                
            } 
            helper.hideSpinner(cmp);
        });
        
        $A.enqueueAction(getDeliveryMethodOptions);
    },
    handleFilesChange: function(cmp,evt,helper){
        var uploadedFiles = evt.getSource().get("v.files");
        if(uploadedFiles.length > 0){
            cmp.set("v.uploadedFileName", uploadedFiles[0].name);
            cmp.set("v.validationPassed", false);
        }
    },
    downloadExampleCsv: function(cmp,evt,helper){
        helper.showSpinner(cmp);
        var selectedFieldValue = cmp.get("v.selectedField");
        var getCsvContent = cmp.get("c.getExampleCsvContent");
        /*getCsvContent.setParams({ 
            selectedField: selectedFieldValue, 
            selectedNum: selectedProdRecs 
        });*/
        getCsvContent.setCallback(this, function(response){
            var getCsvContentState = response.getState(); 
            if (getCsvContentState === "SUCCESS"){
                var csvBody = response.getReturnValue();
                var hiddenElement = document.createElement('a');
                hiddenElement.href = 'data:text/csv;charset=utf-8,' + encodeURI(csvBody);
                hiddenElement.target = '_blank';
                hiddenElement.download = 'exampleTemplateUpload'+'.csv'; 
                hiddenElement.click();
            } 
            helper.hideSpinner(cmp);
        });
        $A.enqueueAction(getCsvContent);
    },
    validateCsvFile: function(cmp,evt,helper){
        helper.showSpinner(cmp);
        var toastEvent = $A.get("e.force:showToast");
        var fileInput = cmp.get("v.csvFile");
        var errFound = false;
        if(fileInput == null){
            toastEvent.setParams({
                title : 'Error',
                message: 'Please attach a file before validating.',
                duration:' 5000',
                key: 'info_alt',
                type: 'error',
                mode: 'sticky'
            });
            errFound = true;
        } else {
            var csvFile = fileInput[0];
            if(csvFile.type != 'text/csv'){
                toastEvent.setParams({
                    title : 'Error',
                    message: 'File type must be CSV.',
                    duration:' 5000',
                    key: 'info_alt',
                    type: 'error',
                    mode: 'sticky'
                });
                errFound = true;
            } else if(csvFile.size > 750000){
                toastEvent.setParams({
                    title : 'Error',
                    message: 'File size cannot exceed 750000 bytes.',
                    duration:' 5000',
                    key: 'info_alt',
                    type: 'error',
                    mode: 'sticky'
                });
                errFound = true;
            } 
        }
        if(errFound == false){
            toastEvent.setParams({
                title : 'Success',
                message: 'Validation of the CSV file passed. You can now upload your templates.',
                duration:' 5000',
                key: 'info_alt',
                type: 'success',
                mode: 'dismissible'
            });
            cmp.set("v.validationPassed", true);
        }
        helper.hideSpinner(cmp);
        toastEvent.fire(); 
    },
    
    handleChange: function (cmp, event) {
        // Get the list of the "value" attribute on all the selected options
        var selectedOptionsList = event.getParam("value");
        alert("Options selected: '" + selectedOptionsList + "'");
    },
    
    prepareCsvFile: function(cmp,evt,helper){
        helper.showSpinner(cmp);
        var pscrecordId = cmp.get("v.recordId")
        console.log('pscrecordId: '+pscrecordId);
        var delmethodSelected = cmp.get("v.selectedField");
        var fileInput = cmp.get("v.csvFile");
        var csvFile = fileInput[0];
        var fr = new FileReader();
        console.log('line 106');
       	fr.onload = $A.getCallback(function(){
            console.log('line 108 - On Load');
            var fileContents = fr.result;
    	    var base64Mark = 'base64,';
            var dataStart = fileContents.indexOf(base64Mark) + base64Mark.length;
            fileContents = fileContents.substring(dataStart);
    	    helper.uploadCsvFile(cmp, csvFile, fileContents,pscrecordId,delmethodSelected);
        });
        fr.readAsDataURL(csvFile);
    }
})