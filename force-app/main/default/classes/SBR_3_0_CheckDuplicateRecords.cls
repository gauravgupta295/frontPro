/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 11-08-2023
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class SBR_3_0_CheckDuplicateRecords {
    @AuraEnabled
    public static List<Contact> duplicateList(Contact contact) {
        List<Contact> contactsList = new List<Contact>();
        contactsList.add(contact);
        List<Contact> response = new List<Contact>();
        try {
            List<Datacloud.FindDuplicatesResult> dups = Datacloud.FindDuplicates.findDuplicates(contactsList);
            for(Datacloud.FindDuplicatesResult dup : dups){
                for(Datacloud.DuplicateResult  res : dup.getDuplicateResults()){
                    for(Datacloud.MatchResult   record : res.getMatchResults()){
                        for(Datacloud.MatchRecord   macthRecord : record.getMatchRecords()){
                            response.add((Contact)macthRecord.getRecord());
                        }
                    }
                }
            }
        } catch (Exception ex) {
            SBR_3_0_Log.logException(ex);
            throw new Duplicate_Exception(ex.getMessage());
        }finally{
            SBR_3_0_Log.saveLog();
        }
        return response;   
    }

    @AuraEnabled
    public static List<String> findDuplicateFields(Contact contact) {
        List<Contact> contactsList = new List<Contact>();
        contactsList.add(contact);
        Set<String> response = new Set<String>();
        try {
            List<Datacloud.FindDuplicatesResult> dups = Datacloud.FindDuplicates.findDuplicates(contactsList);
            for(Datacloud.FindDuplicatesResult dup : dups){
                for(Datacloud.DuplicateResult  res : dup.getDuplicateResults()){
                    for(Datacloud.MatchResult   record : res.getMatchResults()){
                        for(Datacloud.MatchRecord   macthRecord : record.getMatchRecords()){                         
                            for (Datacloud.FieldDiff diff : macthRecord.getFieldDiffs()){
                                if(diff.getDifference().equals('Same')) {
                                    String fieldLabel = getFieldLabel(diff.getName(), 'Contact');
                                    response.add(fieldLabel);
                                }
                            }
                        }
                    }
                }
            }   
        } catch (Exception ex) {
            SBR_3_0_Log.logException(ex);
            throw new Duplicate_Exception(ex.getMessage());
        }finally{
            SBR_3_0_Log.saveLog();
        }
        return  new List<String>(response);
    }

    public static String getFieldLabel(String fieldApiName, String objectApiName) {
        if(fieldApiName == 'Account') return fieldApiName;

        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        Schema.SObjectType leadSchema = schemaMap.get(objectApiName);
        Map<String, Schema.SObjectField> fieldMap = leadSchema.getDescribe().fields.getMap();
        return  fieldMap.get(fieldApiName).getDescribe().getLabel();
    }

    public class Duplicate_Exception extends Exception {}
}