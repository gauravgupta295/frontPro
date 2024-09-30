/*********************************************************************************************************************
* Apex Class: SBR_3_0_API_WorkOrder_Remarketing
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Makes an API call to RichieBros when WorkOrder description is Re-marketing Inspection and status is closed.
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Harry Rokad          2024-01-15            Initial version   
*********************************************************************************************************************/
public with sharing class SBR_3_0_API_WorkOrder_Remarketing {

    private static List<SF_PS_Equipment_Images__c> imgList;
    public static List<Data> data;
    private static final String APINAME = 'API_Richie_Bros_Integration';
    private static final String X_CORRELATION_ID = SBR_3_0_Generic.generateRandomString(10);
    public static  String returnPayload;

    @InvocableMethod(Label = 'CallRichieBrothers')
    public static void callRichieBrothers(List<String> input) {
        if (!input.isEmpty() && !System.isFuture() && !System.isBatch()) {
            createPayload(input);
        }
    }

    @future(Callout = true)
    private static void createPayload(List<String> woId) {
        Set<String> woIdSet = new Set<String>(woId);
        List<WorkOrder> woList = SBR_3_0_WorkOrderDA.getWorkOrders(woIdSet);
        List<Data> dataList = new List<Data>();

        if (!woList.isEmpty()) {
            imgList = [ SELECT Id,Image_Public_Link__c,Image_Name__c,SF_PS_RB_Image_Link__c FROM SF_PS_Equipment_Images__c WHERE SF_PS_Work_Order__c = :woList[0].Id ];
            
            if (!imgList.isEmpty()) {
                String assetNumber = woList[0].Asset.SM_PS_Equipment_Number__c; // Adjust the field name if necessary
                
                for (SF_PS_Equipment_Images__c img : imgList) {
                    Data d = new Data();
                    d.equipmentNumber = assetNumber;
                    d.imageName = img.Image_Name__c;
                    //d.imagePublicLink = img.Image_Public_Link__c;
                    //new Change 
                    d.imagePublicLink=img.SF_PS_RB_Image_Link__c;
                    dataList.add(d);
                }
            }
        }
        
        data = dataList;
        PayloadWrapper payloadWrapper = new PayloadWrapper();
        payloadWrapper.data = data;

        String jsonData = JSON.serialize(payloadWrapper);
        system.debug('Payload' + jsonData);
       SBR_3_0_HttpCallout httpCallout = new SBR_3_0_HttpCallout(APINAME);
                 
        HttpRequest req = httpCallout.getRequest();
        system.debug('X-Correlation-ID'+ X_CORRELATION_ID);
        req.setHeader('X-Correlation-ID', X_CORRELATION_ID);
        req.setHeader('Content-Type', 'application/json');  
        req.setBody(jsonData);
        req.setTimeout(20000);
        Http http = new Http();
        HTTPResponse res = http.send(req);
        returnPayload = res.getBody();
        if(res.getstatusCode() == 200 || res.getstatusCode() == 201){
            system.debug('Success');
        }     
    }

    public class PayloadWrapper {
        public List<Data> data;
    }

    public class Data {
        public String equipmentNumber;
        public String imageName;
        public String imagePublicLink;
    }
}