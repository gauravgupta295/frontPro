/*********************************************************************************************************************
* Apex Class: SBR_3_0_BatchSObjectCloneAndDelete
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Batch clone and delete objects
* - SAL-19738
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Hashem Abdul         2023-04-14             Initial version    
*********************************************************************************************************************/

global class SBR_3_0_BatchSObjectCloneAndDelete implements Database.Batchable<sObject>, Database.Stateful{
   
    String sObjectName = '';
    Map<String,Object> nameValues = new Map<String,Object>();
    String whereClause ='';
    Conversion_Log__c cLog = new Conversion_Log__c();
    String orderBy = '';
    List<String> triggersToByPass = new List<String>();
    List<PricebookEntry> newPBEList = new List<PricebookEntry>();

    global SBR_3_0_BatchSObjectCloneAndDelete(String sObjectName, Map<String,Object> nameValues, String whereClause, String orderBy, Conversion_Log__c cLog,List<PricebookEntry> newPBEList, List<String> triggersToByPass){
        this.sObjectName = sObjectName;
        this.nameValues.putAll(nameValues);
        this.whereClause = whereClause;
        this.orderBy = orderBy;
        this.cLog = cLog;
        this.triggersToByPass = triggersToByPass;
        this.newPBEList = newPBEList;
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {
        List<String> fields = new List<String>();
        SObjectType sObjType = Schema.getGlobalDescribe().get(sObjectName);
        Map<String,Schema.SObjectField> mfields = sObjType.getDescribe().fields.getMap();
        for(String objField: mfields.keySet()){
            fields.add(objField);
        }

        String allFields = String.join(fields, ',');

        String query = 'SELECT ' + allFields 
            + ' FROM ' + sObjectName 
            + ' WHERE ' + whereClause;
        if(String.isNotBlank(orderBy)){
            query += ' Order By ' + orderBy;
        }
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<SObject> scope){
        // By Pass Triggers
        if(!triggersToByPass.isEmpty()){
            for(String trg: triggersToByPass){
                SBR_3_0_TriggerHandler.bypass(trg);
            }
        }
        Map<String, SObject> sObjsToClone = new Map<String, SObject>();
        System.debug('Scope: ' + scope);
        for(SObject obj: scope){
            OrderItem currObj = (OrderItem)obj.clone(false, false, false, false);
            for(String key: nameValues.keySet()){
                currObj.put(key, nameValues.get(key));
            }
            if(sObjectName.equalsIgnoreCase('OrderItem')){
                Id prodId = (String)nameValues.get('Product2Id');
                /* To avoid SOQL in scope
                 List<PricebookEntry> PbEntries = [SELECT Id,unitPrice FROM PricebookEntry WHERE CurrencyIsoCode =: currObj.CurrencyIsoCode AND Product2Id =: prodId];
                if(PbEntries.size() > 0)
                    currObj.put('PricebookEntryId', PbEntries[0].Id);
                	currObj.put('listPrice', PbEntries[0].unitPrice);*/
                
                for(PricebookEntry pbe:newPBEList){
                    if(currObj.CurrencyIsoCode == pbe.CurrencyIsoCode) {
                        currObj.put('PricebookEntryId', pbe.Id);
                		currObj.put('listPrice', pbe.unitPrice);
                    }
                }
            }
            sObjsToClone.put(obj.Id, currObj);
        }


        try {
            
            
            
            // Delete Old Objects
            system.debug('Deleting: ' + scope);
            Database.DeleteResult[] drList = Database.delete(scope, true);
            
            for(Database.DeleteResult dr : drList) {
                if (!dr.isSuccess()) {
                    sObjsToClone.remove(dr.getId());
                }
            }
            
            //Insert Cloned Items
            Insert sObjsToClone.values();
        
            for(SObject obj: sObjsToClone.values()){
                system.debug('Inserted: ' + obj.Id);
            }


        } catch (Exception ex) {
            SBR_3_0_LogException.LogIt(ex, cLog.Id);
            //SAL-25595
            String errorMsg = ex.getMessage() + ' | ' + ex.getStackTraceString();
            SBR_3_0_API_Create_ConversionLog.logError(cLog.Id, errorMsg);
        }

        // Insert Cloned Objects
        system.debug('Inserting: ' + sObjsToClone);
        //Database.SaveResult[] dbSvRslt = Database.insert(sObjsToClone.values(), false);

        system.debug('SObjsToCLone: ' + sObjsToClone);
    }

    global void finish(Database.BatchableContext BC){
       
    }
}