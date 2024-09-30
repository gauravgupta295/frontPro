/*********************************************************************************************************************
* Apex Class: SBR_3_0_WorkOrderTriggerHandler
---------------------------------------------------------------------------------------------------------------------------------------
* @description
* - SERV-15700
* - Class to check when Work Order in Cancel or Closed status cannot be updated
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME                     DATE                 DETAIL FEATURES
    1.0         Diksha Tiwari                      2024-05-28           Initial version
    2.0         Akhil Tyagi                        2024-06-14           Updated metadata query

*********************************************************************************************************************/
public with sharing class SBR_3_0_WorkOrderTriggerHandler {
    
    private static SBR_3_0_AllowedFieldsForWO__mdt editableFieldsMDT{
        get{
            if(editableFieldsMDT == null){
                List<SBR_3_0_AllowedFieldsForWO__mdt> mdtList = [
                    SELECT Id, SF_PS_AllowedFields__c, SF_PS_Error_message__c 
                    FROM SBR_3_0_AllowedFieldsForWO__mdt 
                    WHERE DeveloperName = 'Editable_Fields'
                ];
                if(!mdtList.isEmpty()){
                    editableFieldsMDT = mdtList[0];
                }
            }
            return editableFieldsMDT;
        }
        set;
    }

    public static void checkForWOEditbale(List<WorkOrder> oldWorkOrder, List<WorkOrder> newWorkOrder){
        List<String> allowedFields = editableFieldsMDT.SF_PS_AllowedFields__c.split(',');
        System.debug('value is'+allowedFields);
    
        allowedFields.add('SystemModstamp');
        
        for(Integer index = 0; index < Trigger.size; index++) 
        {
            
            Map<ID, Schema.RecordTypeInfo> recTypeMap = Schema.SObjectType.WorkOrder.getRecordTypeInfosById();
            system.debug('newWorkOrder::'+newWorkOrder[index]);
            String recDeveloperName = recTypeMap.get(newWorkOrder[index].RecordTypeId).getDeveloperName();
            System.debug('dev name'+recDeveloperName);
            
            if((oldWorkOrder[index].Status =='C' || oldWorkOrder[index].Status =='D') && (recDeveloperName == 'SF_PS_Inspection_Record')) 
            {
                
                if(oldWorkOrder[index].SF_PS_Is_Credited__c == false && newWorkOrder[index].SF_PS_Is_Credited__c == true && recDeveloperName =='SF_PS_Inspection_Record')
                {
                    allowedFields.add('SF_PS_Is_Credited__c'); 
                }
                if(oldWorkOrder[index].SF_PS_Is_Converted__c == false && newWorkOrder[index].SF_PS_Is_Converted__c == true && recDeveloperName =='SF_PS_Quote')
                {
                    allowedFields.add('SF_PS_Is_Converted__c'); 
                }
                if((oldWorkOrder[index].Status == 'C' && newWorkOrder[index].Status == 'Closed with Exception') || 
                   (oldWorkOrder[index].Status == 'D' && newWorkOrder[index].Status == 'Cancel with Exception'))
                {
                    allowedFields.add('Status'); 
                    allowedFields.add('SF_PS_Cancel_Closed_Error_Msg__c'); 
                    allowedFields.add('SF_PS_Cancel_Closed_Error_Msg_Code__c'); 
                }
                System.debug('all'+allowedFields);
                
                sObject beforeRecord = oldWorkOrder[index].clone(false, false, false, false);
                sObject afterRecord = newWorkOrder[index].clone(false, false, false, false);
                Map<String, Object> oldValues = beforeRecord.getPopulatedFieldsAsMap();
                Map<String, Object> newValues = afterRecord.getPopulatedFieldsAsMap();
                oldValues.keySet().removeAll(allowedFields);
                newValues.keySet().removeAll(allowedFields);
                System.debug('old values'+JSON.serializePretty(oldValues));
                System.debug('new values'+JSON.serializePretty(newValues));
                WorkOrder oldValuesWO = (WorkOrder) JSON.deserialize(JSON.serialize(oldValues), WorkOrder.class);
                WorkOrder newValuesWO = (WorkOrder) JSON.deserialize(JSON.serialize(newValues), WorkOrder.class);
                if(oldValuesWO != newValuesWO)
                {
                   newWorkOrder[index].addError(editableFieldsMDT.SF_PS_Error_message__c);
                }
            }
        }
    }
}