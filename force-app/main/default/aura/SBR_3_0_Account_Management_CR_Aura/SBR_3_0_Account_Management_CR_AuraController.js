({
	doInit : function(component, event, helper) {
        var workspaceAPI = component.find("workspace");
        var TabaName = $A.get("$Label.c.SBR_3_0_Account_Management_CR_Tab_Name");
        workspaceAPI.getFocusedTabInfo().then(function(response) {
            var focusedTabId = response.tabId;
            workspaceAPI.setTabLabel({
                tabId: focusedTabId,
                label: TabaName
            });
            workspaceAPI.setTabIcon({
                tabId: focusedTabId,
                icon: "standard:account",
                iconAlt: TabaName,
            });
        })
        .catch(function(error) {
            console.log(error);
        });
    }
})