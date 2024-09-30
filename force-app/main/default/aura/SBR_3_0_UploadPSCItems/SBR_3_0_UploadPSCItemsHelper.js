({
	showSpinner: function(cmp){
        cmp.set("v.spinner", true); 
    },
    hideSpinner: function(cmp){ 
        cmp.set("v.spinner", false);
    },
    uploadCsvFile: function(cmp,file,fileContents,pscrecordId,delmethodSelected){
        console.log('in helper');
        var toastEvent = $A.get("e.force:showToast");
        var templateCreate = cmp.get("c.preparePSCItems"); 
        templateCreate.setParams({ 
            fileName: file.name,
            base64Data: encodeURIComponent(fileContents), 
            delmethodSelected : delmethodSelected,
            pscRecordId : pscrecordId
        });
        console.log('line 17 helper');
        templateCreate.setCallback(this, function(response){
            var templateCreateState = response.getState(); 
            console.log('templateCreateState'+templateCreateState);
            if (templateCreateState === "SUCCESS"){
                var templateCreateResponse = response.getReturnValue();
                if(templateCreateResponse == "SUCCESS"){
                    toastEvent.setParams({
                        title : 'Success',
                        message: 'Product Service Campaign Items will be created shortly. Please refresh after a minute.',
                        duration:' 5000',
                        key: 'info_alt',
                        type: 'success',
                        mode: 'dismissible'
                    });
                } else {
                    toastEvent.setParams({
                        title : 'Error',
                        message: templateCreateResponse,
                        duration:' 5000',
                        key: 'info_alt',
                        type: 'error',
                        mode: 'sticky'
                    });
                }
            } else {
                toastEvent.setParams({
                    title : 'Error',
                    message: 'Something went wrong!',
                    duration:' 5000',
                    key: 'info_alt',
                    type: 'error',
                    mode: 'sticky'
                });
            }
            cmp.set("v.spinner", false);
            toastEvent.fire(); 
            $A.get('e.force:refreshView').fire();
        });
        $A.enqueueAction(templateCreate);
    }
})