/**
 * @description       : Create, Update, or Delete SObjects asynchronously
 * @author            : Hashem Abdul
 * @group             : 
 * @last modified on  : 02-02-2024
 * @last modified by  : Hashem Abdul
**/
public with sharing class SBR_3_0_Queueable_CUD_SObject implements Queueable, Database.AllowsCallouts {
    
    private List<SObject> lstObjects;
    private String operation; // Create, Update, or Delete


    public SBR_3_0_Queueable_CUD_SObject(List<SObject> lstSObjects, String operation) {
        this.lstObjects = lstSObjects;
        this.operation = operation;
    }

    public void execute(QueueableContext context){
        try {
            if(this.operation.equalsIgnoreCase('Create')){
                Insert this.lstObjects;
            } else if(this.operation.equalsIgnoreCase('Update')){
                Update this.lstObjects;
            } else if(this.operation.equalsIgnoreCase('Delete')){
                Delete this.lstObjects;
            }
        } catch (Exception ex) {
            SBR_3_0_LogException.LogIt(ex);
            throw ex;
        }
    }
}