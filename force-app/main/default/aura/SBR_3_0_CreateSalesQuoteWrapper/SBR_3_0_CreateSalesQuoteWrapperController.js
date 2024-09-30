({
    init : function (component) {
        // Find the component whose aura:id is "flowData"
        var flow = component.find("flowData");
        flow.startFlow("SBR_3_0_Create_Standard_Quote_frontline");
    },
})