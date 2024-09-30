({
    doInit : function(cmp, evt, helper) {
        var myPageRef = cmp.get("v.pageReference");
        var id = myPageRef.state.c__id;
        var objectName =  myPageRef.state.c__objectName[0].toUpperCase() + myPageRef.state.c__objectName.substring(1);
        myPageRef.state.c__objectName[0].toUpperCase() + myPageRef.state.c__objectName.substring(1);
        if(objectName && id){
            cmp.set("v.callLWC", true);
        }
        cmp.set("v.recordIds", id);
        cmp.set("v.sObjectNames", objectName);
    },
    handleCloseAction : function(cmp, evt, helper) {
        var myPageRef = cmp.get("v.pageReference");
        var id = myPageRef.state.c__id;
        var navigateEvent = $A.get("e.force:navigateToSObject");
        navigateEvent.setParams({
            "recordId": id,
            "slideDevName": "detail"
        });
        navigateEvent.fire();
    }
})