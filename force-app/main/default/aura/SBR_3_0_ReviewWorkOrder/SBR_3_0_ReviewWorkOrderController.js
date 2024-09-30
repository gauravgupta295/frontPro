({
    init : function (component) {
        let pageRef = component.get("v.pageReference");
        if(pageRef){
            component.set("v.recordId", pageRef.state.c__recordId);
            
            let inputVariables = [{
                name  : "recordId",
                type  : "String",
                value : pageRef.state.c__recordId
            }];
            // Embedd the flow
            let flow = component.find("flowData");
            flow.startFlow("SBR_3_0_Review_Auto_Generated_Work_Order", inputVariables);
        } else {
            component.find("navService").navigate({
                "type" : "standard__component",
                "attributes" : {
                    "componentName" : "c__SBR_3_0_ReviewWorkOrder"
                },
                "state" : {
                    "c__recordId" : component.get("v.recordId")
                }
            });
        }
    },

    handleStatusChange : function (component, event) {
        if(event.getParam("status") === "FINISHED") {
            let workspaceAPI = component.find('workspace');
            workspaceAPI.isConsoleNavigation().then(function(response) {
                if(response){
                    let focusedTabId;
                    workspaceAPI.getFocusedTabInfo().then(function(response) {
                        focusedTabId = response.tabId;
                        workspaceAPI.openTab({
                            pageReference : {
                                "type" : "standard__recordPage",
                                "attributes" : {
                                    "recordId"   : component.get("v.recordId"),
                                    "actionName" : "view"
                                }
                            },
                            focus : true
                        }).then(function(tabId) {
                            workspaceAPI.refreshTab({
                                tabId             : tabId,
                                includeAllSubtabs : true
                            });
                            workspaceAPI.closeTab({tabId : focusedTabId}).then(function(response) {
                                console.log('@@@@ cancel response ==>> ', response);
                            });
                        });
                    }).catch(function(error) {
                        console.log(error);
                    });
                } else {
                    component.find("navService").navigate({
                        "type" : "standard__recordPage",
                        "attributes" : {
                            "recordId"   : component.get("v.recordId"),
                            "actionName" : "view"
                        }
                    });
                }
            })
        }
    },
})