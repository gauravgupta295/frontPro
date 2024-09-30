({
  onPageReferenceChange: function (cmp, evt, helper) {
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
        });

        // component.set("v.flowName", state[FLOW_NAME]);
        // component.set("v.inputVariables", inputVariables);
      }
    }
  },
  handleSetFlowName: function (cmp, event, helper) {
    let flowName = event.getParam("flowName");
    let workspaceAPI = cmp.find("workspace");
    if (workspaceAPI) {
      workspaceAPI
        .isConsoleNavigation()
        .then((isConsole) => {
          if (isConsole) {
            return workspaceAPI.getFocusedTabInfo();
          }
        })
        .then(function (response) {
          let focusedTabId = response.tabId;
          workspaceAPI.setTabLabel({
            tabId: focusedTabId,
            label: flowName
          });
        })
        .then(function (response) {
          workspaceAPI.setTabIcon({
            icon: "standard:default"
          });
        })
        .catch(function (error) {
          console.log(error);
        });
    }
  }
});