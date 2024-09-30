({
    handleCloseFromLWC: function(component, event) {
        var recordId = event.getParam('newRecordId');
        // component.set('v.message', 'Close Clicked');

        if ($A.get("$Browser.isPhone")) {
            //navigate to new lead
            let lwcForm = component.find("createLeadRecordCmp");
            if (lwcForm) {
                lwcForm.resetForm();
            }
            var navEvt = $A.get("e.force:navigateToSObject");
            navEvt.setParams({
                "recordId": recordId
            });
            $A.get("e.force:closeQuickAction").fire();
            $A.get("e.force:refreshView").fire();
            navEvt.fire();
        } else {
            var width = component.find("container").getElement().clientWidth;
            if(width > 1640){
            //get tab that has the create lead cmp in it so that it can be closed
            var workspaceAPI = component.find("workspace");
            //close the tab with the create lead record cmp
            workspaceAPI.getFocusedTabInfo().then(function(response) {
                    var focusedTabId = response.tabId;
                    workspaceAPI.closeTab({ tabId: focusedTabId });
                    return recordId;

                    //navigate to the newly created lead record
                })
                .then(function(response) {
                    $A.get("e.force:closeQuickAction").fire(); // SF-6118
                    workspaceAPI.openTab({
                        url: '#/sObject/' + response + '/view',
                        focus: true
                    });
                })
                .catch(function(error) {
                    console.log(error);
                });
            }else{
                //navigate to new lead
                let lwcForm = component.find("createLeadRecordCmp");
                if (lwcForm) {
                    lwcForm.resetForm();
                }
                var navEvt = $A.get("e.force:navigateToSObject");
                navEvt.setParams({
                    "recordId": recordId
                });
                $A.get("e.force:closeQuickAction").fire();
                $A.get("e.force:refreshView").fire();
                navEvt.fire();
            }
        }
    },
    //handleClose only handles closing the component if the x is hit and cancel, 
    //save will close it through the LWC using handleCloseFromLWC
    handleClose: function(component, event, helper) {
        console.log('inside aura handleClose method ');
        var dismissActionPanel = $A.get("e.force:closeQuickAction");
        dismissActionPanel.fire();
        
        var rid = component.get("v.recordId");
        console.log('rid ', rid);
        var workspaceAPI = component.find("workspace");
        console.log('workspaceAPI ', workspaceAPI);
        let pageRef = component.get('v.pageReference');
        console.log('pageRef ', pageRef);
        let xAction = pageRef ? pageRef.state.c__xAction : '';
        console.log('xAction -> ', xAction);


        if (rid) {
            var navEvt = $A.get("e.force:navigateToSObject");
            navEvt.setParams({
                "recordId": component.get("v.recordId"),
                "slideDevName": "detail"
            });
            workspaceAPI.getFocusedTabInfo().then(function(response) {
                var focusedTabId = response.tabId;
                console.log('tab id ', focusedTabId);
                workspaceAPI.closeTab({ tabId: focusedTabId });
            })
            navEvt.fire();

        } else if (xAction == 'closeModal') {
            console.log('closing modal...');

            //close the tab with the create lead record cmp
            workspaceAPI.getFocusedTabInfo().then(function(response) {
                var focusedTabId = response.tabId;
                workspaceAPI.closeTab({ tabId: focusedTabId });
            });


        } else {
            var navEvt = $A.get("e.force:navigateToObjectHome");
            navEvt.setParams({
                "scope": "Lead"
            });
            if ($A.get("$Browser.formFactor") == "DESKTOP") {
                
                if(pageRef && pageRef.attributes.objectApiName === 'Lead'){
                    workspaceAPI.getFocusedTabInfo().then(function(response) {
                        var focusedTabId = response.tabId;
                        workspaceAPI.closeTab({ tabId: focusedTabId });
                    });
                }
            } else {
                let lwcForm = component.find("createLeadRecordCmp");
          
            }
            //navEvt.fire();// SF-6118
        }
    },

    checkClientEnvironment: function(component, event, helper) {
        var isMobile = $A.get("$Browser.formFactor") === "PHONE";
        component.set("v.isMobile", isMobile);
    },


    // handleSubmit: function(component, event, helper) {
    //     var childComponent = component.find('createLeadRecordCmp');
    //     childComponent.handleSubmit(event);
    // }

})