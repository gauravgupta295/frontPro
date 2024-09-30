({
    
  init : function (cmp) {
    var flow = cmp.find("flowData");
    flow.startFlow("SBR_3_0_Create_Cart");
  },

    //Flow Status Change
    statusChange : function (component, event, helper) {
        //Check Flow Status
        if (event.getParam('status') === "FINISHED_SCREEN" || event.getParam('status') === "FINISHED") {
         var outputVariables = event.getParam("outputVariables");
         var outputVar;
         var cartRecordId;
         for(var i = 0; i < outputVariables.length; i++) {
            outputVar = outputVariables[i];
            // Pass the values to the component's attributes
            if(outputVar.name === "CartRecord") {
                	cartRecordId = outputVar.value.Id;
		    } 
         }

       	 var navService = component.find("navService");
            var pageReference = {
            type: 'standard__recordPage',
            attributes: {
                actionName: 'view',
                objectApiName: 'Cart__c',
                recordId : cartRecordId // change record id. 
            },
        };
        //event.preventDefault();
        navService.navigate(pageReference);
        var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                title: "Success!",
                message: "Cart Created Successfully",
                type: "success"
            });
            toastEvent.fire();
        
        } else if (event.getParam('status') === "ERROR") {
            component.set("v.hasError", true);
        }
    },   
})