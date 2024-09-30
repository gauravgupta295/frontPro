({
    invoke: function (component, event, helper) {
        var navService = component.find('navService');
        var recordId = component.get('v.recordId');
        var objectName = component.get('v.sObject');
    
        var pageReference = {
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                objectApiName: objectName,
                actionName: 'view'
            }
         
        }
        navService.navigate(pageReference,true);   
    }        
})