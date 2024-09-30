({
    init : function (component) {
        ///lightning/cmp/c__SBR30flowExecutionAURA?c__flowName=SBR_3_0_Create_Rates_Quote_From_Quote_List
        var recordId = component.get("v.recordId");
        var sObjectName = component.get("v.sObjectName");
        let inputVariables=[];
        console.log('value is ',recordId);
        inputVariables.push({
            "name": "recordId",
            "type": "String",
            "value": recordId
        });
        inputVariables.push({
            "name": "sObjectName",
            "type": "String",
            "value": sObjectName
        });
        let data=JSON.parse(JSON.stringify(inputVariables));
        console.log(JSON.stringify(inputVariables));
        console.log(data);
        var flow = component.find("flowData");
        
        flow.startFlow("SBR_3_0_SFS_Update_Travel_And_Labor_Screen",inputVariables);
        
    },
    genericMethod:function(cmp)
    {/*
        var myPageRef = cmp.get("v.pageReference");
        const state = myPageRef.state;
        const FLOW_NAME = "c__flowName";
        if (state) {
          const clonedState = Object.assign({}, state);
          const lightningFlow = cmp.find("lightningFlow");
          if (clonedState[FLOW_NAME]) {
            delete clonedState[FLOW_NAME];
            const inputVariables = [];
            for (let param of Object.keys(clonedState)) {
              if (param.startsWith("c__")) {
                let name = param.replace("c__", "").trim();
                let value = clonedState[param];
                inputVariables.push({
                  name,
                  value,
                  type: "String"
                });
              }
            }
            let flowName = state[FLOW_NAME];
            let workspaceAPI = cmp.find("workspace");
            workspaceAPI.getFocusedTabInfo().then(function (response) {
              let focusedTabId = response.tabId;
              workspaceAPI
                .setTabLabel({
                  tabId: focusedTabId,
                  label: flowName
                })
                .then(function (response) {
                  workspaceAPI.setTabIcon({
                    icon: "standard:default"
                  });
                })
                .then(() => {
                  lightningFlow.startFlow(flowName, inputVariables);
                  console.log("## ", inputVariables);
                });
            });*/
    },
    handleStatusChange : function (cmp, event) {
        console.log(event.getParam("status"));
        if(event.getParam("status") === "FINISHED") {
            var workspaceAPI = cmp.find("workspace");
            workspaceAPI.getFocusedTabInfo().then(function(response) {
               var focusedTabId = response.tabId;
                console.log(focusedTabId);
                workspaceAPI.closeTab({tabId: focusedTabId});
            })
            .catch(function(error) {
                console.log(error);
            });
            console.log('flow finished');
            
                 var navEvt = $A.get("e.force:navigateToSObject");
            navEvt.setParams({
                "recordId": cmp.get("v.recordId")
            });
            navEvt.fire();
             
           
        }
    }
})