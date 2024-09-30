({
    handleModalClose: function (component, event, helper) {
        const payload = event.getParam('payload') || {};
        const closemodal = payload.closeModal;
        var eventParams = event.getParams();
        if (closemodal) {
            $A.get("e.force:closeQuickAction").fire();
        }
    },

    doInit: function(component, event, helper) {
        const recordId = component.get("v.recordId");
        const action = component.get("c.getOrderAmountDetails");
        action.setParams({ recordId: recordId });

        action.setCallback(this, function(response) {
            const state = response.getState();
            if (state === "SUCCESS") {
                const order = response.getReturnValue();
                const totalAmount = order.Total_Rental_Amount__c;
                const invoiceAmount = order.Total_Invoiced_Amount__c;

                if (totalAmount > invoiceAmount) {
                    component.set("v.showMakeADeposit", true);
                }else{
                    component.set("v.showMakeADeposit", false);
                }


            } else if (state === "ERROR") {
                const errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.error("Error message: " + errors[0].message);
                    }
                }
            }
        });

        $A.enqueueAction(action);
    }

})