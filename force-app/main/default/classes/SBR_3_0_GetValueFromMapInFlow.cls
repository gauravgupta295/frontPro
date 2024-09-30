/*********************************************************************************************************************
* Apex Class: SBR_3_0_GetValueFromMapInFlow
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Class to retrieve value from apex-defined map variable type SBR_3_0_GetRecordTypesFlowMapClass in Flows
* - SAL-852
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Avinash Rao           2022-02-17            Initial version    
*********************************************************************************************************************/
public class SBR_3_0_GetValueFromMapInFlow {
    @AuraEnabled
    public string key; //Map key
    
    @AuraEnabled
    public string value; //Map value
    
	@InvocableMethod(label='Get Value from a Map key')
    public static GetValueOutputs[] getValue(getValueInputs[] input	){
        GetValueOutputs[] result = new GetValueOutputs[]{};
        
        for(SBR_3_0_GetRecordTypesFlowMapClass loopObj : input[0].flowMap){
            if(loopObj.key == input[0].key){
                GetValueOutputs obj = new GetValueOutputs();
                obj.outputValue = loopObj.value;
                result.add(obj);
                return result;
            }
        }
        return result;        
    }
    
    public class GetValueInputs{
        @InvocableVariable(label='Key' required=true)
        public string key;
        
        @InvocableVariable(label='Map' required=true)
        public SBR_3_0_GetRecordTypesFlowMapClass[] flowMap;
    }
    
    public class GetValueOutputs{
        @InvocableVariable(label='Value' required=true)
        public string outputValue;
    }
}