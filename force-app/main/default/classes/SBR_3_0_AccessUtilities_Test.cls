@isTest()
public with sharing class SBR_3_0_AccessUtilities_Test
{
    public SBR_3_0_AccessUtilities_Test()
    {
    }

    @isTest
    public static void testisIdAccesible()
    {
        Test.startTest();
        User checkAccess = new User();
        String[] accessFields = new String[]{ 'Id' };
        Boolean isAccessable = SBR_3_0_AccessUtilities.isAccesible((SObject) checkAccess, accessFields);
        Assert.areEqual(true, isAccessable, 'User Id field should be accessible.');
        Test.stopTest();
    }
    
    @isTest
    public static void testisIdAccesibleStr()
    {
        Test.startTest();
        String checkAccessStr = 'User';
        String[] accessFields = new String[]{ 'Id' };
            Map<String, Boolean> isAccessable = SBR_3_0_AccessUtilities.isAccesible(checkAccessStr, accessFields);
        Assert.areEqual(true, isAccessable.get('Id'), 'User Id field should be accessible.');
        Test.stopTest();
    }
    
    @isTest
    public static void testIsIdNotCreatable()
    {
        Test.startTest();
        User checkAccess = new User();
        String[] accessFields = new String[]{ 'Id'};
        Boolean isCreatable = SBR_3_0_AccessUtilities.isCreateable((SObject) checkAccess, accessFields);
        Assert.areEqual(false, isCreatable, 'User Id field should not be creatable.');
        Test.stopTest();
    }
    @isTest
    public static void testIsNameCreatable()
    {
        Test.startTest();
        User checkAccess = new User();
        String[] accessFields = new String[]{ 'Name'};
        Boolean isCreatable = SBR_3_0_AccessUtilities.isCreateable((SObject) checkAccess, accessFields);
        Assert.areEqual(false, isCreatable, 'User Name field should not be creatable.');
        Test.stopTest();
    }
    @isTest
    public static void testIsNameCreatableStr()
    {
        Test.startTest();
        String checkAccessStr = 'User';
        String[] accessFields = new String[]{ 'Name'};
            Map<String, Boolean> isCreatable = SBR_3_0_AccessUtilities.isCreateable(checkAccessStr, accessFields);
        Assert.areEqual(false, isCreatable.get('Name'), 'User Name field should not be creatable.');
        Test.stopTest();
    }
    @isTest
    public static void testIsNameUpdateatable()
    {
        Test.startTest();
        User checkAccess = new User();
        String[] accessFields = new String[]{ 'Name'};
        Boolean isUpdateable = SBR_3_0_AccessUtilities.isUpdateable((SObject) checkAccess, accessFields);
        Assert.areEqual(false, isUpdateable, 'User Name field should not be updatable.');
        Test.stopTest();
    }
    @isTest
    public static void testIsUsernameUpdateatable()
    {
        Test.startTest();
        User checkAccess = new User();
        String[] accessFields = new String[]{ 'Username'};
        Boolean isUpdateable = SBR_3_0_AccessUtilities.isUpdateable((SObject) checkAccess, accessFields);
        Assert.areEqual(true, isUpdateable, 'User Username field should be updatable.');
        Test.stopTest();
    }
    
    @isTest
    public static void testIsNameUpdateatableStr()
    {
        Test.startTest();
        String checkAccessStr = 'User';
        String[] accessFields = new String[]{ 'Name'};
            Map<String, Boolean> isUpdateable = SBR_3_0_AccessUtilities.isUpdateable(checkAccessStr, accessFields);
        Assert.areEqual(false, isUpdateable.get('Name'), 'User Name field should not be updatable.');
        Test.stopTest();
    }
    @isTest
    public static void testIsMissingFieldError()
    {
        Test.startTest();
        User checkAccess = new User();
        String[] accessFields = new String[]{ 'really random field'};
        Boolean isUpdateable = SBR_3_0_AccessUtilities.isUpdateable((SObject) checkAccess, accessFields);
        Assert.areEqual(false, isUpdateable, 'User random field should be not found.');
        Test.stopTest();
    }
    
    @isTest
    public static void testIsMissingFieldErrorStr()
    {
        Test.startTest();
        String checkAccessStr = 'User';
        String[] accessFields = new String[]{ 'really random field'};
            Map<String, Boolean> isUpdateable = SBR_3_0_AccessUtilities.isUpdateable(checkAccessStr, accessFields);
        Assert.areEqual(false, isUpdateable.get('really random field'), 'User random field should be not found.');
        Test.stopTest();
    }
    
}