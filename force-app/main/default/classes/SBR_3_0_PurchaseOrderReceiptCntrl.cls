public class SBR_3_0_PurchaseOrderReceiptCntrl {

    public class ReceiptRecord{
       @AuraEnabled public List<PO_Receipt__c> receiptRec;
       @AuraEnabled public List<List<PO_Receipt__c>> receiptRcvRec;
       @AuraEnabled public Decimal totalCost;
    }
    
    @AuraEnabled(cacheable=true)
    public static ReceiptRecord getReceiptRecords(Id recordId){
        List<PO_Receipt__c> receiptRecord = new List<PO_Receipt__c>([SELECT Id,Receiver_Number__c,Receiver_Seq__c,Messages__c,Qty_On_Hand__c, Date_Received__c, 
                                                                            PO_Line_Item__r.Item_Number__c, PO_Line_Item__r.Item_Description_Calc__c,
                                                                            Status__c, Reason_Code__c, Quantity_Received__c, Units__c,  Unit_Cost__c,
                                                                            PO_Line_Item__r.Total_Cost_Calc__c,Adjust_Credit_Ind__c
                                                                       FROM PO_Receipt__c
                                                                      WHERE Purchase_Order__c =: recordId
                                                                      ORDER BY Receiver_Seq__c ]);
        
        List<PO_Receipt__c> receiptCmntRec = new List<PO_Receipt__c>();
        Map<Decimal,List<PO_Receipt__c>> receiverRecMap = new Map<Decimal,List<PO_Receipt__c>>();
        Decimal totalCostCal = 0;
        
        for(PO_Receipt__c rec : receiptRecord){
            totalCostCal = totalCostCal + (rec.Quantity_Received__c * rec.Unit_Cost__c);
            if(receiverRecMap.containsKey(rec.Receiver_Number__c)){
                receiverRecMap.get(rec.Receiver_Number__c).add(rec);
            }
            else{
                receiverRecMap.put(rec.Receiver_Number__c,new List<PO_Receipt__c>{rec});
                receiptCmntRec.add(rec);
            }
        }
        
        ReceiptRecord record = new ReceiptRecord();
        record.receiptRec = new List<PO_Receipt__c>(receiptCmntRec);
        record.receiptRcvRec = new List<List<PO_Receipt__c>>(receiverRecMap.values());
        record.totalCost = totalCostCal;
        
        return record;
    }
    
    //Nikhil FRONT-11627
    @AuraEnabled(cacheable=false)
    public static List<PO_Receipt__c> getReceiptDetails(List<Id> receiptIds) {
        System.debug('selectedReceiptIds :'+receiptIds);
        
        try {  
            return [SELECT Id, Receiver_Seq__c,Qty_On_Hand__c, Date_Received__c, PO_Line_Item__r.Item_Number__c,Item_Desc__c, PO_Line_Item__r.Item_Description_Calc__c,
                    Quantity_Received__c, Unit_Cost__c FROM PO_Receipt__c WHERE ID IN :receiptIds];
        }
        catch(Exception ex) {
            SBR_3_0_LogException.LogIt(ex) ;
            throw new AuraHandledException(ex.getMessage());
        }
    }
    @AuraEnabled
    public static String createPOReceipts(string poReceipts, string reason, string poRecId) {
        // Temporary placeholder until RM integration has been setup
        // this will generate a value to put into the Receive Number field
        String dtString = String.valueOf(system.now()).replaceAll('-','').replaceAll(' ','').replaceAll(':','').substring(6);
        String dtStringNew = String.valueOf(system.now().addHours(22)).replaceAll('-','').replaceAll(' ','').replaceAll(':','').substring(6);
        string returnVal = 'Success';
        try {
            Integer maxSeq = 0;
            List<AggregateResult> maxSeqRecps = [SELECT Max(Receiver_Seq__c) MaxValue FROM PO_Receipt__c WHERE Purchase_Order__c =:poRecId];
            maxSeq = Integer.valueOf(maxSeqRecps[0].get('MaxValue'));
            System.debug('maxSeq: ' + maxSeq);
            System.debug('poReceipts: ' + poReceipts);
            List<PO_Receipt__c> newPOReceipts = new List<PO_Receipt__c>();
            List<PO_Receipt__c> orgPORecipts = new List<PO_Receipt__c>();
            List<PO_Receipt__c> poRecpsList = new List<PO_Receipt__c>();
            List<PO_Receipt__c> updPOReceipts = new List<PO_Receipt__c>();
            orgPORecipts = (List<PO_Receipt__c>) JSON.deserialize(poReceipts, List<PO_Receipt__c>.class );
            System.debug('orgPORecipts: ' + orgPORecipts);
            Set<Id> recIds = (new Map<Id,SObject>(orgPORecipts)).keySet();
            Map<Id, PO_Receipt__c> orgRecpsMap = new Map<Id, PO_Receipt__c>(orgPORecipts);
            System.debug('orgRecpsMap: ' + orgRecpsMap);
            List<PO_Line_Item__c> updPOLineItems = new List<PO_Line_Item__c>();
            for(PO_Receipt__c poReceipt : orgPORecipts) {
                PO_Line_Item__c poLI = new PO_Line_Item__c();
                poLI.Id = poReceipt.PO_Line_Item__c;
                if(poReceipt.Quantity_Received__c != null) {
                    poLI.Quantity__c = poReceipt.Quantity_Received__c;
                }
                if(poReceipt.Unit_Cost__c != null) {
                    poLI.Unit_Cost__c = poReceipt.Unit_Cost__c;
                }
                updPOLineItems.add(poLI);
            }
            System.debug('updPOLineItems: ' + updPOLineItems);
            if(updPOLineItems.size() > 0) {
                update updPOLineItems;
            }
            if(orgPORecipts.size() > 0) {
                poRecpsList = [SELECT Id,Receiver_Number__c,Receiver_Seq__c,Messages__c, Date_Received__c, Purchase_Order__c,
                                        PO_Line_Item__r.Item_Number__c, PO_Line_Item__r.Item_Description_Calc__c,
                                        Status__c, Reason_Code__c, Quantity_Received__c, Units__c,  Unit_Cost__c, PO_Line_Item__c,
                                        PO_Line_Item__r.Total_Cost_Calc__c, Adj_Receiver_Seq__c, Transaction_Cost__c, Adjust_Credit_Ind__c
                                        FROM PO_Receipt__c
                                        WHERE Id IN:recIds LIMIT 49999];
                for(PO_Receipt__c rcp : poRecpsList) {
                    //RA Receipt
                    PO_Receipt__c raRecp = new  PO_Receipt__c();
                    raRecp.Receiver_Number__c = Decimal.valueOf(dtString);
                    raRecp.Status__c = 'RA';
                    raRecp.Reason_Code__c = reason;
                    raRecp.Quantity_Received__c = Decimal.valueOf('-' + rcp.Quantity_Received__c);
                    raRecp.Unit_Cost__c = rcp.Unit_Cost__c;
                    raRecp.PO_Line_Item__c = rcp.PO_Line_Item__c;
                    raRecp.Transaction_Cost__c = raRecp.Quantity_Received__c * raRecp.Unit_Cost__c;
                    raRecp.Receiver_Seq__c = maxSeq + 1;
                    raRecp.Date_Received__c = Date.today();
                    raRecp.Adjust_Credit_Ind__c = 'CRD';
                    raRecp.Purchase_Order__c = rcp.Purchase_Order__c;
                    newPOReceipts.add(raRecp);
                    System.debug('raRecp: ' + raRecp);
                    //RC Receipt
                    PO_Receipt__c rcRecp = new  PO_Receipt__c();
                    rcRecp.Receiver_Number__c = Decimal.valueOf(dtStringNew);
                    rcRecp.Status__c = 'RC';
                    rcRecp.Quantity_Received__c = orgRecpsMap.get(rcp.Id).Quantity_Received__c != null ? orgRecpsMap.get(rcp.Id).Quantity_Received__c : rcp.Quantity_Received__c;
                    rcRecp.Unit_Cost__c = orgRecpsMap.get(rcp.Id).Unit_Cost__c != null ? orgRecpsMap.get(rcp.Id).Unit_Cost__c : rcp.Unit_Cost__c;
                    rcRecp.PO_Line_Item__c = rcp.PO_Line_Item__c;
                    rcRecp.Transaction_Cost__c = rcRecp.Quantity_Received__c * rcRecp.Unit_Cost__c;
                    rcRecp.Receiver_Seq__c = maxSeq + 2;
                    rcRecp.Date_Received__c = Date.today();
                    rcRecp.Purchase_Order__c = rcp.Purchase_Order__c;
                    newPOReceipts.add(rcRecp);
                    System.debug('rcRecp: ' + rcRecp);
                    //Update original
                    rcp.Adjust_Credit_Ind__c = 'ADJ';
                    updPOReceipts.add(rcp);
                }
            }
            if(newPOReceipts.size() > 0) {
                System.debug('newPOReceipts: ' + newPOReceipts);
                insert newPOReceipts;
            }
            if(updPOReceipts.size() > 0) {
                System.debug('updPOReceipts: ' + updPOReceipts);
                update updPOReceipts;
            }
        } catch (Exception ex) {
            SBR_3_0_LogException.LogIt(ex);
            returnVal = 'Failure';
        }
        return returnVal;
    }
}