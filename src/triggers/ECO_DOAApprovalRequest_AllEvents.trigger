trigger ECO_DOAApprovalRequest_AllEvents on DOAApprovalRequest__c (before update, after insert, after update) {
    
    if(trigger.isbefore && trigger.isUpdate){
        ECO_DOAApprovalRequestTriggerHandler.handleDOAApprovalStamping(trigger.new);
    }

    if(trigger.isAfter)
        ECO_DOAApprovalRequestTriggerHandler.handleDOAApprovalRequestChange(trigger.new);
        
    if( trigger.isBefore && ( trigger.isUpdate || trigger.isInsert ) ){       
        
        ECO_Service_RecordAccess.getProjectRecordAccess( trigger.new );
    }         

}