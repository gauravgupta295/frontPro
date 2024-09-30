/*********************************************************************************************************************
* Apex Class: SBR_3_0_SendgridEmailRequestUtility
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Utility class for Request Payload.
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Piyush Jindal           2023-11-15          Initial version
    2.0         Piyush Jindal           2023-11-22          Updated oldToNewAttributeMap variable.
---------------------------------------------------------------------------------------------------------------------------------------
Note:-
* 
*********************************************************************************************************************/
public with sharing class SBR_3_0_SendgridEmailRequestUtility {
    public static final String WO_EMAIL_API_NAME                 = Label.SBR_3_0_Sendgrid_WO_Email_API;
    public static final String WO_TEMPLATE_ACTIVITY_TYPE         = Label.SBR_3_0_Sendgrid_Activity_Type_for_WO_Email;
    public static final String COMPANY_CODE                      = Label.SBR_3_0_Sendgrid_Company_Code_for_WO_Email;
    public static final Map<String, String> oldToNewAttributeMap = new Map<String, String> {
        'null'                => '\"\"',
        'toEmailAddresses'    => 'Tos',
        'emailDetails'        => 'EmailDetails',
        'communicationData'   => 'CommunicationData',
        'attachments'         => 'Attachments',
        'activityType'        => 'ActivityType',
        'fileContent'         => 'AttachementContent',
        'fileName'            => 'FileName',
        'mimeType'            => 'MimeType',
        'disposition'         => 'Disposition',
        'workOrderData'       => 'workOrder'
    };

    /*********************************************************************************************************************
    * Purpose/Methods:
    * Removes attribute from String and returns the updated String.
    *********************************************************************************************************************/
    public static String removeAttributeFromSerializedData (String serializedData, List<String> attributeList) {
        Map<String, Object> dataMap = (Map<String, Object>)JSON.deserializeUntyped(serializedData);

        for(String attribute : attributeList) {
            dataMap.remove(attribute);
        }
        
        return JSON.serialize(dataMap);
    }

    /*********************************************************************************************************************
    * Purpose/Methods:
    * Replace attributes from String and returns the updated String.
    *********************************************************************************************************************/
    public static String replaceAttributeInData (String serializedData, Map<String, String> oldToNewAttributeMap) {
        String updatedSerializedData = serializedData;

        for(String oldAttribute : oldToNewAttributeMap.keySet()) {
            updatedSerializedData = updatedSerializedData.replace(oldAttribute, oldToNewAttributeMap.get(oldAttribute));
        }
        
        return updatedSerializedData;
    }
}