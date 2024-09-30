({
    closeModal : function(component, event, helper) {
        $A.get("e.force:closeQuickAction").fire();    
	},
 handleRecordUpdated: function(component, event, helper) {
        var eventParams = event.getParams();
            if(eventParams.changeType === "LOADED") {
                var wo = component.get("v.workOrderRecord");  
                component.set("v.showChild","true");
                if(wo.Account.E_mail_Address__c){
                    component.set("v.isCustomerEmail","true");
                }
            } 
        }
        
})