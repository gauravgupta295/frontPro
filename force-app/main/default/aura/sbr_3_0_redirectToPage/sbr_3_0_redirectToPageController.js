({
invoke : function(component, event, helper) {
var redirectToNewRecord = $A.get( "e.force:navigateToSObject" );

redirectToNewRecord.setParams({
"recordId": component.get( "v.recordId" ),
"slideDevName": "detail"
});
redirectToNewRecord.fire();
}
})
// ({ this does not work
//     invoke : function(component, event, helper) {
//     var redirectToNewRecord = $A.get( "e.force:navigateToURL" );
//     var url = '/' + 'SBQQ__Quote__c' + '/' + component.get( "v.recordId").toString() + '/view'
//     redirectToNewRecord.setParams({
//     "url": url
//     });
//     redirectToNewRecord.fire();
//     }
//     })