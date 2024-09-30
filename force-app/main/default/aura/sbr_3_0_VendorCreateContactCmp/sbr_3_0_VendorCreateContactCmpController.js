({
    doInit: function (component, event, helper) {
        // Do Nothing
    },
    
    //handleClose only handles closing the component if the x is hit and cancel, save will close it through the LWC using handleCloseFromLWC
    handleClose: function (component, event, helper) {
        var navEvt = $A.get("e.force:navigateToSObject");
        navEvt.setParams({
            recordId: component.get("v.recordId"),
            isredirect : true            
        }); 
            
        navEvt.fire();
    },
    
    handleSuccess: function (component, event) {
        console.log('device::'+$A.get("$Browser.formFactor"));
        var recordId = event.getParam("newRecordId");
        var workspaceAPI = component.find("workspace");
        //close the tab with the create lead record cmp 
        //Added as part of FRONT-13991
         if(recordId && ($A.get("$Browser.formFactor")=="PHONE" || $A.get("$Browser.formFactor")=="TABLET") ){
               var navEvt = $A.get("e.force:navigateToSObject");
            navEvt.setParams({
                recordId: recordId,
				isredirect : true                
            }); 
            
            navEvt.fire();
             }
        else{
        workspaceAPI
            .getFocusedTabInfo()
            .then(function (response) {
                var focusedTabId = response.tabId;
                workspaceAPI.closeTab({ tabId: focusedTabId });
                return recordId;
                
                //navigate to the newly created lead record
            })
            .then(function (response) {
                workspaceAPI.openTab({
                    url: "#/sObject/" + response + "/view",
                    focus: true
                });
            })
            .catch(function (error) {
                console.log(error);
            });
         }        
    },
    
    handleScroll: function (component, event) {
        var modal = component.find("modal").getElement();
        modal.scrollTo(0, 0);
    }
});