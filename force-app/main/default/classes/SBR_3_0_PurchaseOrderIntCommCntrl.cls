public with sharing class SBR_3_0_PurchaseOrderIntCommCntrl {
	@AuraEnabled
    public static List<PO_Internal_Comments__c> getInternalComments(Id recordId)
    {
        system.debug('recordId:'+recordId);
        List<PO_Internal_Comments__c> poInternalCommentsList;
        poInternalCommentsList=[SELECT CreatedBy.Wynne_User_Name__c,CreatedDate,Id,Created_Date__c,Created_By__c,Comments__c
                        		FROM PO_Internal_Comments__c 
                                WHERE Purchase_Order__c=:recordId];
        return poInternalCommentsList;
    }

    @AuraEnabled
    public static void createOrUpdatePOInternalComments(Id recordId, Id selectedCommentIds, String oldCommentValue, String newCommentValue, Date commentDate, String createdBy) {
        Id currentUserID = UserInfo.getUserId();
        Date dateValue = getDateInstanceFromCreatedDate(commentDate);
        User currentUser = [SELECT Id, Wynne_User_Name__c FROM User WHERE Id = :currentUserID LIMIT 1];
        String currentUserWynneUserName;
        String createdByWynneUserName;

        if(!Test.isRunningTest()) {
        	currentUserWynneUserName = currentUser.Wynne_User_Name__c;
        	createdByWynneUserName = createdBy != null ? createdBy : currentUser.Wynne_User_Name__c;            
        }
        else {
        	currentUserWynneUserName = 'DEPLOY';
        	createdByWynneUserName = 'DEPLOY';
        }

        updateOrCreateComment(recordId, selectedCommentIds, oldCommentValue, newCommentValue, dateValue, createdByWynneUserName, currentUserWynneUserName);
    }

    private static void updateOrCreateComment(Id recordId, Id selectedCommentIds, String oldCommentValue, String newCommentValue, Date commentDate, String createdByWynneUserName, String currentUserWynneUserName) {
        List<PO_Internal_Comments__c> existingComments = new List<PO_Internal_Comments__c>();

        // Build SOQL query based on the parameters
        String existingCommentsQuery = 'SELECT Id, Comments__c, Created_By__c, Created_Date__c FROM PO_Internal_Comments__c';
        if (selectedCommentIds != null) {
            existingCommentsQuery += ' WHERE Id = :selectedCommentIds';
        } else if (currentUserWynneUserName != null && commentDate != null) {
            existingCommentsQuery += ' WHERE Purchase_Order__c = :recordId AND Created_By__c = :createdByWynneUserName AND Created_Date__c = :commentDate ORDER BY Created_Date__c DESC LIMIT 1';
        }

        // Execute the query outside of if-else blocks to avoid code duplication
        existingComments = Database.query(existingCommentsQuery);
        
        if (!existingComments.isEmpty()) {
            PO_Internal_Comments__c existingComment = existingComments[0];
            if (selectedCommentIds != null && existingComment.Comments__c.contains(oldCommentValue)) {
                // Update existing comment
                existingComment.Comments__c = existingComment.Comments__c.replace(oldCommentValue, newCommentValue);
            } else {
                // Append comment value if length allows, otherwise create new comment
                Boolean isNotBlank = (!String.isBlank(existingComment.Comments__c) || existingComment.Comments__c != null );
                Integer existingLength = isNotBlank ? existingComment.Comments__c.length() : 0;
                if (existingLength + newCommentValue.length() <= 1960) {
                    existingComment.Comments__c = isNotBlank ? existingComment.Comments__c + newCommentValue : newCommentValue;
                } else {
                    createNewPOInternalComment(recordId, newCommentValue, createdByWynneUserName);
                    return;
                }
            }
            existingComment.Last_Modified_By__c = currentUserWynneUserName;
            existingComment.Last_Modified__c = System.now();

            // Update existing comment
            try {
                update existingComment;
            } catch (Exception e) {
                System.debug('Error updating existing comment: ' + e.getMessage());
            }
        } else {
            // Create new comment
            createNewPOInternalComment(recordId, newCommentValue, createdByWynneUserName);
        }
    }

    private static void createNewPOInternalComment(Id recordId, String commentValue, String createdByWynneUserName) {
        try {
            PO_Internal_Comments__c newComment = new PO_Internal_Comments__c();
            newComment.Purchase_Order__c = recordId;
            newComment.Comments__c = commentValue;
            newComment.Created_By__c = createdByWynneUserName;
            newComment.Created__c = System.now();
            newComment.Last_Modified_By__c = createdByWynneUserName;
            newComment.Last_Modified__c = System.now();
            insert newComment;
            System.debug('New comment created: ' + newComment);
        } catch (Exception e) {
            System.debug('Error creating new comment: ' + e.getMessage());
        }
    }

    private static Date getDateInstanceFromCreatedDate(Date commentDate) {
        Date dateValue = null;
        if (commentDate != null) {
            Integer year = commentDate.year();
            Integer month = commentDate.month();
            Integer day = commentDate.day();
            
            try {
                dateValue = Date.newInstance(year, month, day);
            } catch (Exception e) {
                System.debug('Error creating Date instance: ' + e.getMessage());
            }
        } else {
            Date now = Date.today();
            dateValue = Date.newInstance(now.year(), now.month(), now.day());
        }

        return dateValue;
    }
}