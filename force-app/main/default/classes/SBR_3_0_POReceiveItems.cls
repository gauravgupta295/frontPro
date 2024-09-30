public with sharing class SBR_3_0_POReceiveItems {
    
    public class customException extends Exception {}
    
    @AuraEnabled(cacheable=true)
    public static List<ProductItem> getUserProductItemsByProductIds(List<Id> productIds){
        
        Id currentUserId = UserInfo.getUserId();
        User_Location__c currentUserLocation = [SELECT Id, Name, ProfileBranche__c  
                                                FROM User_Location__c 
                                                WHERE User__c =: currentUserId
                                                LIMIT 1];
        
        return 
            [
                SELECT  Id, 
                Product2Id, 
                SM_PS_Branch_Location_Number__c, 
                SM_PS_Bin_Location_1__c, 
                SM_PS_Bin_Location_2__c, 
                SM_PS_Bin_Location_3__c, 
                SerialNumber
                FROM 
                ProductItem 
                WHERE 
                Product2Id IN :productIds 
                AND 
                SM_PS_Branch_Location_Number__c = :currentUserLocation.ProfileBranche__c 
                LIMIT 49999
            ];
        
    }
    
    
    @AuraEnabled
    public static string receiveMiscItems(string purchaseOrderId, string receiveItemsString, string receiverComments){
        String returnVal = '';
        System.debug('receiveItemsString: ' + receiveItemsString);
        try {
            List<PO_Receipt__c> receiveItemList = new List<PO_Receipt__c>();
            receiveItemList = (List<PO_Receipt__c>) JSON.deserialize(receiveItemsString, List<PO_Receipt__c>.class);
            System.debug('receiveItemList: ' + receiveItemList);
            string poStatus;
            integer statusCounter = 0;
            boolean isSuccess = true;
            
            Purchase_Order__c po = [SELECT Id, Vendor_Number__c, Name, Company_Code__c, Location__c, Status__c FROM Purchase_Order__c WHERE Id = :purchaseOrderId];
            System.debug('po: ' + po);
            
            Id currentUserId = UserInfo.getUserId();
            User_Location__c currentUserLocation = [SELECT Id, Name, ProfileBranche__r.Branch_Location_Number__c  
                                                    FROM User_Location__c 
                                                    WHERE User__c =: currentUserId
                                                    LIMIT 1];
            
            Map<Id, PO_Receipt__c> poLineItemsMap = new Map<Id, PO_Receipt__c>();
            // Temporary placeholder until RM integration has been setup
            // this will generate a value to put into the Receive Number field
            String dtString = String.valueOf(system.now()).replaceAll('-','').replaceAll(' ','').replaceAll(':','').substring(6);

            
            for(PO_Receipt__c receiveItem : receiveItemList){
                // Temporary placeholder until RM integration has been setup
                // this will generate a value to put into the Receive Number field
                receiveItem.Receiver_Number__c = Decimal.valueOf(dtString);
                receiveItem.Receiver_Seq__c = 1;
				// End of temporary placeholder
				
                receiveItem.Vendor_Number__c = po.Vendor_Number__c;
                if(!String.isBlank(po.Name)){
                    receiveItem.PO_Number__c = Decimal.valueOf(po.Name);                    
                }
                receiveItem.Company_Code__c = po.Company_Code__c;
                receiveItem.Status__c = 'RC';
                receiveItem.Messages__c = receiverComments;
                receiveItem.Location__c = po.Location__c;
                receiveItem.Received_Location__c = currentUserLocation.ProfileBranche__r.Branch_Location_Number__c;
                receiveItem.Date_Received__c = Date.today();
                receiveItem.Time_Received__c = Decimal.valueOf(datetime.now().format('HHmmss'));
                poLineItemsMap.put(receiveItem.PO_Line_Item__c, receiveItem);
            }
            
            List<PO_Line_Item__c> poLineItems = [SELECT Id, Quantity__c, Quantity_Rcvd__c, Open_Order_Qty__c, Unit_Cost__c, Status__c FROM PO_Line_Item__c WHERE Purchase_Order__c = :purchaseOrderId];
            
            for(PO_Line_Item__c poLineItem : poLineItems){
                if(poLineItemsMap.containsKey(poLineItem.Id)){
                    if(poLineItemsMap.get(poLineItem.Id).Quantity_Received__c != null){
                        poLineItem.Quantity_Rcvd__c = ((poLineItem.Quantity_Rcvd__c != null) ? poLineItem.Quantity_Rcvd__c : 0) + poLineItemsMap.get(poLineItem.Id).Quantity_Received__c;
                        poLineItem.Open_Order_Qty__c = (poLineItem.Quantity__c - poLineItem.Quantity_Rcvd__c > 0) ? poLineItem.Quantity__c - poLineItem.Quantity_Rcvd__c : null;
                        poLineItem.Status__c = (poLineItem.Open_Order_Qty__c != null && poLineItem.Open_Order_Qty__c > 0) ? 'Back Order' : 'Received';
                    }
                    poLineItem.Unit_Cost__c = poLineItemsMap.get(poLineItem.Id).Unit_Cost__c;
                }else{
                    if(poLineItem.Status__c == 'Open' || string.isBlank(poLineItem.Status__c)){
                        poLineItem.Status__c = 'Back Order';
                        poLineItem.Open_Order_Qty__c = poLineItem.Quantity__c;
                    }
                }
                
                if(poLineItem.Status__c == 'Received' || poLineItem.Status__c == 'Cancelled'){
                    statusCounter++;
                }
                else if(poLineItem.Status__c == 'Back Order' || poLineItem.Status__c == 'Partially Received'){
                    poStatus = 'Back Order';
                }
            }
            
            if(statusCounter == poLineItems.size()){
                poStatus = 'Received';
            }                    
            
            Savepoint sp = Database.setSavepoint(); 
            
            try {
                List<string> outputRes = new List<string>();
                List<string> outputErrors = new List<string>();
                Database.SaveResult[] saveResultsReceiveItems = Database.insert(receiveItemList);
                // Iterate over the save results
                for (Database.SaveResult saveResult : saveResultsReceiveItems) {
                    if (saveResult.isSuccess()) {
                        //System.debug('Record Succesffully updated '+saveResult.getId());
                        outputRes.add('PO Receive Item: ' + saveResult.getId() + ' created successfully.');
                    } 
                    else {
                        // Record failed to insert/update
                        for (Database.Error error : saveResult.getErrors()) {
                            //System.debug('Record Failed'+error);
                            outputErrors.add('PO Receive Item: ' + saveResult.getId() + ' create failed.');
                        }
                        isSuccess = false;
                    }
                }
                
                if(!isSuccess){
                    throw new customException('Error creating Receive Item records. Failed with following errors: ' + outputErrors);
                }
                
                returnVal = string.join(outputRes, '\n');
                
                Database.SaveResult[] saveResultsLineItems = Database.update(poLineItems);
                // Iterate over the save results
                for (Database.SaveResult saveResult : saveResultsLineItems) {
                    if (saveResult.isSuccess()) {
                        //System.debug('Record Succesffully updated '+saveResult.getId());
                        outputRes.add('PO Line Item: ' + saveResult.getId() + ' updated successfully.');
                    } 
                    else {
                        // Record failed to insert/update
                        for (Database.Error error : saveResult.getErrors()) {
                            //System.debug('Record Failed'+error);
                            outputErrors.add('PO Line Item: ' + saveResult.getId() + ' update failed.');
                        }
                        isSuccess = false;
                    }
                }
                if(!isSuccess){
                    throw new customException('Error updating PO Line Item records. Failed with following errors: ' + outputErrors);
                }
                returnVal = returnVal + string.join(outputRes, '\n');
                
                if(!String.isBlank(poStatus)){
                    po.Status__c = poStatus;
                    Database.SaveResult savePOResult = Database.update(po);
                    if (savePOResult.isSuccess()) {
                        outputRes.add('PO: ' + savePOResult.getId() + ' updated successfully.');
                    } 
                    else {
                        for (Database.Error error : savePOResult.getErrors()) {
                            outputErrors.add('PO: ' + savePOResult.getId() + ' update failed.');
                        }
                        isSuccess = false;
                    }
                    if(!isSuccess){
                        throw new customException('Error updating Purchase Order. Failed with following errors: ' + outputErrors);
                    }
                    returnVal = returnVal + string.join(outputRes, '\n');
                }
            }
            catch (Exception ex) {
                Database.rollback(sp);
                SBR_3_0_LogException.LogIt(ex);
                System.debug('error: '+ex);
                if(!Test.isRunningTest()) {
                    throw new AuraHandledException(ex.getMessage());                
                }
            }
        }
        catch(Exception ex) {
            System.debug('An Exception: '+ex);
            if(!Test.isRunningTest()) {
                throw new AuraHandledException(ex.getMessage());                
            }
        }
        return returnVal;
    }
    
}