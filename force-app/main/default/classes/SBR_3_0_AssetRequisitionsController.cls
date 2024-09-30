//class containing methods to operate on Purchase Order
public with sharing class SBR_3_0_AssetRequisitionsController {
   
    @AuraEnabled (cacheable=true)
    public static List<PO_Requisition__c> getAssetReqs(String recordId) {
        String branchLoc = '';
        String vendNumber = '';
        
        List<Purchase_Order__c> purchOrd = [SELECT Id, Location__c, Vendor_Number__c FROM Purchase_Order__c WHERE Id = :recordId];
        if(purchOrd.size() > 0) {
            branchLoc = purchOrd[0].Location__c;
            vendNumber = purchOrd[0].Vendor_Number__c;
        }
        
        return [SELECT Id, Requisition_Num__c, Quantity__c, Item_Number__c, Status__c, Due_Date__c,Requisition_Type__c,
                		Contract_Num__c, Approval_Level__c,Maintained_By__c,Requisition_Date__c, Item_Desc__c, Added_By__c
                  FROM PO_Requisition__c
                 WHERE Order_Location__c = :branchLoc
                   AND Vendor_Number__c = :vendNumber
                   AND Status__c='O'
                   AND Item_Desc__c != null
              ];
	}
        
    @AuraEnabled
    public static void createPOLineItem(Id recordId, String purchaseOrder) {
        List<PO_Requisition__c> reqList = new List<PO_Requisition__c>();
        Id RecordTypeId = [SELECT Id FROM RecordType WHERE sObjectType = 'PO_Line_Item__c' AND DeveloperName = 'Standard_Purchase_Order'].Id;

        try{
        	reqList = [SELECT Id, Name,Requisition_Num__c, Item_Number__c,Status__c, Driv_Lic_State__c, Discount_Pct1__c, Discount_Pct2__c, 
                              Discount_Pct3__c,Driv_Lic_Num__c,Drop_Shipment__c,Due_Date__c,Equipment_Num__c,Equipment_Type__c,
                              GL_Account__c,Quantity__c,Unit_Cost__c,Item_Desc__c,Added_By__c
                         FROM PO_Requisition__c
                        WHERE Id = :recordId];

            System.debug(reqList);
            System.debug(purchaseOrder);
            System.debug(recordId);

            if(reqList.size() > 0) {
                if (reqList[0].Status__c == 'O'){
            		PO_Line_Item__c polineitem = New PO_Line_Item__c();
                    polineitem.RecordTypeId = RecordTypeId;
                    polineitem.Source__c = 'SF';
                    polineitem.Item_Type__c = 'E';
                    polineitem.Item_Desc__c = reqList[0].Item_Desc__c;
                    polineitem.Item_Number__c = reqList[0].Item_Number__c;
                    polineitem.Driver_Lic_State__c = 	reqList[0].Driv_Lic_State__c;
                    polineitem.Discount_Pct1__c = reqList[0].Discount_Pct1__c;
                    polineitem.Discount_Pct2__c = reqList[0].Discount_Pct2__c;
                    polineitem.Discount_Pct3__c = reqList[0].Discount_Pct3__c;
                    polineitem.Driver_Lic_Num__c = reqList[0].Driv_Lic_Num__c;
                    polineitem.Drop_Shipment__c = reqList[0].Drop_Shipment__c;
                    polineitem.Due_Date__c = 	reqList[0].Due_Date__c;
                    polineitem.Equipment_Num__c = reqList[0].Equipment_Num__c;
                    polineitem.Equipment_Type__c = reqList[0].Equipment_Type__c;
                    polineitem.GL_Account__c = reqList[0].GL_Account__c;
                    polineitem.Quantity__c = 	reqList[0].Quantity__c;
                    polineitem.Unit_Cost__c = reqList[0].Unit_Cost__c;
                    polineitem.Purchase_Order__c = purchaseOrder;
                    polineitem.PO_Requisition__c = recordId;
            		insert polineitem;
                    
                    reqList[0].Status__c = 'P';
            		update reqList;
                }                
            }
            
        }
        catch(Exception e) { 
            SBR_3_0_LogException.LogIt(e);
            throw new AuraHandledException('Error Caught'); 
		}
    }
}