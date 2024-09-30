({
    doInit: function (component, event, helper) {
        var pageRef = component.get("v.pageReference");
        var accId = pageRef.state.c__accId;
        component.set("v.accId",accId);
        console.log('accId::'+accId);
        // var accId = component.get("v.accId");
        //alert("PageRef:" + JSON.stringify(pageRef));
        /*var state = pageRef.state;
    var base64Context = state.inContextOfRef;
    if (base64Context && base64Context.startsWith("1.")) {
      base64Context = base64Context.substring(2);
    }
    var addressableContext = JSON.parse(window.atob(base64Context));
    component.set("v.recordId", addressableContext.attributes.recordId);
    //component.set("v.recordId", accId);*/
  },
    
    //handleClose only handles closing the component if the x is hit and cancel, save will close it through the LWC using handleCloseFromLWC
    handleClose: function (component, event, helper) {
        var rid = component.get("v.recordId");
        var workspaceAPI = component.find("workspace");
        let pageRef = component.get("v.pageReference");
        let xAction = pageRef.state.c__xAction;
        if (rid) {
            var navEvt = $A.get("e.force:navigateToSObject");
            navEvt.setParams({
                recordId: component.get("v.recordId"),
                slideDevName: "detail"
            });
            workspaceAPI.getFocusedTabInfo().then(function (response) {
                var focusedTabId = response.tabId;
                workspaceAPI.closeTab({ tabId: focusedTabId });
            });
            navEvt.fire();
        } else if (xAction == "closeModal") {
            //close the tab with the create lead record cmp
            workspaceAPI.getFocusedTabInfo().then(function (response) {
                var focusedTabId = response.tabId;
                workspaceAPI.closeTab({ tabId: focusedTabId });
            });
        } else {
            var navEvt = $A.get("e.force:navigateToObjectHome");
            navEvt.setParams({
                scope: "Contact"
            });
            if ($A.get("$Browser.formFactor") == "DESKTOP") {
                workspaceAPI.getFocusedTabInfo().then(function (response) {
                    var focusedTabId = response.tabId;
                    workspaceAPI.closeTab({ tabId: focusedTabId });
                });
            }
            else if (($A.get("$Browser.formFactor") == "PHONE" || $A.get("$Browser.formFactor") == "TABLET")) {

                if (component.get("v.accId")) {
                    var navEvt = $A.get("e.force:navigateToSObject");
                    navEvt.setParams({
                        recordId: component.get("v.accId"),
                        isredirect: true

                    });
                }
                else {
                    var navEvt = $A.get("e.force:navigateToObjectHome");
                    navEvt.setParams({
                        scope: "Contact"
                    });
                }

                navEvt.fire();
            }
            //navEvt.fire();
        }
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