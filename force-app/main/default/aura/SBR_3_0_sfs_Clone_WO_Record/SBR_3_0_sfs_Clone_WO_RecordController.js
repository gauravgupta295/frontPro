({
    init : function(component, event, helper) {
        let recordId=component.get('v.recordId');
        let  url='/flow/SBR_3_0_SFS_Clone_WorkOrder?recordId='+recordId;
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
            "url": url
        });
        urlEvent.fire();
    }
    
});