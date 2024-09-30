public with sharing class SBR_3_0_AccessUtilities {

    public enum TypeOfAccessCheck
    {
        ACCESIBLE, 
        CREATEABLE, 
        UPDATEABLE
    }

    @AuraEnabled
    public static Map<String, Boolean> isCreateable(String toCheckObject, String[] fieldstoCheck)
    {
        return hasRight(TypeOfAccessCheck.CREATEABLE, toCheckObject, fieldstoCheck);
    }

    @AuraEnabled
    public static Map<String, Boolean> isUpdateable(String toCheckObject, String[] fieldstoCheck)
    {
        return hasRight(TypeOfAccessCheck.UPDATEABLE, toCheckObject, fieldstoCheck);
    }

    @AuraEnabled
    public static Map<String, Boolean> isAccesible(String toCheckObject, String[] fieldstoCheck)
    {
        return hasRight(TypeOfAccessCheck.ACCESIBLE, toCheckObject, fieldstoCheck);
    }

    public static boolean isCreateable(SObject toCheckObject, String[] fieldstoCheck) 
    {
        return hasRight(TypeOfAccessCheck.CREATEABLE, toCheckObject, fieldstoCheck);
    }
    public static boolean isUpdateable(SObject toCheckObject, String[] fieldstoCheck)
    {
        return hasRight(TypeOfAccessCheck.UPDATEABLE, toCheckObject, fieldstoCheck);
    }
    public static boolean isAccesible(SObject toCheckObject, String[] fieldstoCheck)
    {
        return hasRight(TypeOfAccessCheck.ACCESIBLE, toCheckObject, fieldstoCheck);
    }

    private static Map<String, Boolean> hasRight(TypeOfAccessCheck typeOfCheck, String toCheckObject, String[] fieldstoCheck)
    {
        Map<String, Boolean> res = new Map<String, Boolean>();
        Boolean result = true;
        Schema.DescribeSObjectResult describeSObjectResult = ((SObject) Type.forName(toCheckObject).newInstance()).getSObjectType().getDescribe();
        Map<String, Schema.SObjectField> mapSchema = describeSObjectResult.fields.getMap();
        String sObjectType = describeSObjectResult?.getName();
        String stypeOfCheck = typeOfCheck.name().toLowerCase().capitalize();
        for (String fieldToCheck : fieldstoCheck) {
            Schema.SObjectField sObjectField = mapSchema.get(fieldToCheck);
            if (sObjectField == null)
            {
                res.put(fieldToCheck, false);
            } else {
                Schema.DescribeFieldResult describeFieldResult = sObjectField.getDescribe();
                switch on typeOfCheck
                {
                    when ACCESIBLE
                    {
                        res.put(fieldToCheck,describeFieldResult.isAccessible());
                    }
                    when CREATEABLE
                    {
                        res.put(fieldToCheck,describeFieldResult.isCreateable());
                    }
                    when UPDATEABLE
                    {
                        res.put(fieldToCheck,describeFieldResult.isUpdateable());
                    }
                }
            }
        }
        return res;
    }

    private static Boolean hasRight(TypeOfAccessCheck typeOfCheck, SObject toCheckObject, String[] fieldstoCheck)
    {
        Boolean result = true;
        Schema.DescribeSObjectResult describeSObjectResult = toCheckObject.getSObjectType().getDescribe();
        Map<String, Schema.SObjectField> mapSchema = describeSObjectResult.fields.getMap();
        String sObjectType = describeSObjectResult?.getName();
        String stypeOfCheck = typeOfCheck.name().toLowerCase().capitalize();
        for (String fieldToCheck : fieldstoCheck)
        {
            Schema.SObjectField sObjectField = mapSchema.get(fieldToCheck);
            if (sObjectField == null)
            {
                result = false;
            } else
            {
                Schema.DescribeFieldResult describeFieldResult = sObjectField.getDescribe();
                switch on typeOfCheck
                {
                    when ACCESIBLE
                    {
                        result = describeFieldResult.isAccessible();
                    }
                    when CREATEABLE
                    {
                        result = describeFieldResult.isCreateable();
                    }
                    when UPDATEABLE
                    {
                        result = describeFieldResult.isUpdateable();
                    }
                }

            }
            if (!result)
            {
                break;
            }

        }
        return result;
    }
}