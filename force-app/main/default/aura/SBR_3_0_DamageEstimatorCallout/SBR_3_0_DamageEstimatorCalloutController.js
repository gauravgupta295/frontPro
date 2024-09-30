({
    invoke : function(component, event, helper) {
        //const helper = this;
        //alert(component.get("v.greeting") + ", " + component.get("v.subject"));
        return new Promise( $A.getCallback( function( resolve, reject ) {

            const action = component.get("c.createDamageEstimator");
            action.setParams({"damageEstimatorId": component.get("v.damageEstimatorId")});
            action.setCallback(this, function(response) {
                if (component.isValid() && response.getState() === 'SUCCESS') {
                    console.log('response======',response.getReturnValue());
                    if(response.getReturnValue() && response.getReturnValue().damageEstimatorSuccessWrap) {
                        component.set("v.responseType", 'SUCCESS');
                        component.set("v.invoiceNumber", response.getReturnValue().damageEstimatorSuccessWrap.damageInvoiceNumber);
                        component.set("v.invoiceSequenceNumber", response.getReturnValue().damageEstimatorSuccessWrap.sequenceNumber);
                    }
                    else if(response.getReturnValue() && response.getReturnValue().damageEstimatorErrorWrap) {
                        component.set("v.responseType", 'EXIST');
                    }
                    else {
                        component.set("v.responseType", 'ERROR');
                    }
                    resolve(response.getReturnValue());

                } else {
                    component.set("v.responseType", 'ERROR');
                    console.error( 'Error calling action "' + actionName + '" with state: ' + response.getState());
                    reject( response.getError() );

                }
            });
            $A.enqueueAction(action);

        }));
    }
})