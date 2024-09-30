({
    init : function (component,event) {
        //   var flow = component.find("flowData");
        /*var inputVariables = [
            {
                name : "IDFrecordID",
                type : "Text",
                value : component.get("v.recordId")
    
            }
    
        ];*/
        //flow.startFlow("Disclosure_Review_V21",inputVariables);
        //flow.startFlow("SBR_3_0_SFS_WorkOrder_Creation");
        var redirectURL = 'https://'+window.location.host+'/flow/SBR_3_0_SFS_New_WorkOrder_Quote_Creation';
        console.log(redirectURL);
        var redirect = $A.get("e.force:navigateToURL");
        redirect.setParams({
            "url": redirectURL
        });
        redirect.fire();
        
    },
})