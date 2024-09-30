//class containing methods to operate on Purchase Order
public with sharing class SBR_3_0_POItemSearchController {
    //method to return list of records for an object with parameterised field and filter
    @AuraEnabled(cacheable=true)
    public static List<Product2> getProduct(String recordId,String objectName,List<String> fieldName,String filterBy){
        String companyCode = [select Company_Code__c from Purchase_Order__c where id =: recordId].Company_Code__c;
        String query = 'Select ' + String.join(fieldName,',') + ' From ' + objectName + ' where ' + filterBy + ' and Company_Code__c =: companyCode and Status__c = \'A\' Limit 100';  
        // String query = 'SELECT ' + String.join(fieldName, ',') + ' FROM ' + objectName + ' WHERE ' + filterBy + ' AND Company_Code__c = :companyCode AND Status__c = \'A\' ORDER BY CreatedDate DESC LIMIT 100';

        return DataBase.query(query);
    }
        
    @AuraEnabled
    public static void createPOLineItem(Id recordId, String singleRecordId,Double newSingleUnitValue, String singleItemNumber, Decimal singleQuantity,String stockclass) {
        
        Id RecordTypeId = [SELECT Id FROM RecordType WHERE sObjectType = 'PO_Line_Item__c' AND DeveloperName = 'Standard_Purchase_Order'].Id;
        String companyCode = [select Company_Code__c from Purchase_Order__c where id =: recordId].Company_Code__c;
        
        try {            
        	System.debug(RecordTypeId);
            PO_Line_Item__c po_New_Record = new PO_Line_Item__c();
            po_New_Record.Company_Code__c = companyCode;
            po_New_Record.Purchase_Order__c = recordId;
            po_New_Record.Source__c = 'SF';
            po_New_Record.Item_Desc__c = singleRecordId;
            po_New_Record.Unit_Cost__c= newSingleUnitValue;
            po_New_Record.Item_Number__c= singleItemNumber;
			po_New_Record.Quantity__c=singleQuantity;
        	po_New_Record.Stock_Class__c=stockclass;
        	po_New_Record.RecordTypeId=RecordTypeId;
            System.debug(po_New_Record);
            insert po_New_Record;
        }
        catch (Exception e) {
            SBR_3_0_LogException.LogIt(e) ;
			throw new AuraHandledException('Failed to create PO Line Item:');
        }
    }
    
    @AuraEnabled
    public static void createBulkPOLineItem(Id recordId, List<String> RowsIds,List<Double> RowsCostValues, List<String> RowsItemNumbers ,List<Decimal> values,List<String> selectedRowsStockValues) {
        List<PO_Line_Item__c> insertProductList=new List<PO_Line_Item__c>();
        Id RecordTypeId = [SELECT Id FROM RecordType WHERE sObjectType = 'PO_Line_Item__c' AND DeveloperName = 'Standard_Purchase_Order'].Id;       
        String companyCode = [select Company_Code__c from Purchase_Order__c where id =: recordId].Company_Code__c;        

        try {        
            for (Integer i = 0; i <RowsIds.size() ; i++) {
                PO_Line_Item__c po_New_Record = new PO_Line_Item__c();    	
                po_New_Record.Company_Code__c = companyCode;
                po_New_Record.Purchase_Order__c = recordId;
                po_New_Record.Source__c = 'SF';
                po_New_Record.Quantity__c=values[i];
                po_New_Record.Stock_Class__c=selectedRowsStockValues[i];
                po_New_Record.Item_Desc__c = RowsIds[i];
                po_New_Record.Unit_Cost__c= RowsCostValues[i];
                po_New_Record.Item_Number__c= RowsItemNumbers[i];
                po_New_Record.RecordTypeId=RecordTypeId;
                
                insertProductList.add(po_New_Record);   
            }
            
            System.debug(insertProductList);

            insert insertProductList;
        }
        catch (Exception e) {
        	SBR_3_0_LogException.LogIt(e) ;
			throw new AuraHandledException('Failed to create PO Line Items:');
		}
	}
}