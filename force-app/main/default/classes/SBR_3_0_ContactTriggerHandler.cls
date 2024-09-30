/*****************************************************************************************************
* Apex Class: SBR_3_0_ContactTriggerHandler
------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Calls methods from SBR_3_0_ContactOperations based on trigger context
------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME                      DATE                DETAIL FEATURES
    1.0         Philippe Bilodeau                   2023-03-17          Initial version
*****************************************************************************************************/
public class SBR_3_0_ContactTriggerHandler extends SBR_3_0_TriggerHandler {
	@TestVisible
    private List<Contact> oldContactList;
    @TestVisible
    private List<Contact> newContactList;

    public SBR_3_0_ContactTriggerHandler()
    {
        this.oldContactList = (List<Contact>)Trigger.old;
        this.newContactList = (List<Contact>)Trigger.new;
    }

    public override void beforeInsert()
    { 
        SBR_3_0_ContactOperations.populateParentAccountOnContact(this.newContactList);
    }

    public override void beforeUpdate()
    {
        SBR_3_0_ContactOperations.populateParentAccountOnContact(this.newContactList);
    }
}