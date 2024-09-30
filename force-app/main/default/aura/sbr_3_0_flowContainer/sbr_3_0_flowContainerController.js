({
    doInit: function (component, event, helper) {
        var pageReference = component.get("v.pageReference");
        if (pageReference) {
            var state = pageReference.state;
            var flow = component.find("flowData");
            var inputVariables = [
                {
                    name: 'source',
                    type: 'String',
                    value: state.c__source
                }
            ];
            flow.startFlow(state.c__flowName, inputVariables);
        }
    },

    handleStatusChange: function (component, event) {
        if (event.getParam("status") === "FINISHED") {

            var outputVariables = event.getParam("outputVariables");

            var outputVar;

            for (var i = 0; i < outputVariables.length; i++) {
                outputVar = outputVariables[i];
                if (outputVar.name === "recordDetailId") {
                    var urlEvent = $A.get("e.force:navigateToSObject");
                    urlEvent.setParams({
                        "recordId": outputVar.value,
                        "isredirect": "true"
                    });
                    urlEvent.fire();
                }
            }
        }
    }
})