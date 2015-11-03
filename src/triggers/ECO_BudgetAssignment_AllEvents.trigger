trigger ECO_BudgetAssignment_AllEvents on BudgetAssignment__c (
    before insert, 
    before update, 
    before delete, 
    after insert, 
    after update, 
    after delete, 
    after undelete) {

    if (Trigger.isBefore && Trigger.isInsert) {
        ECO_BudgetAssignmentTriggers.setRateDefaults(trigger.new);
    } else if (Trigger.isAfter) {
/*              
        if ((trigger.isInsert) || (trigger.isUpdate)) {
            try{
                ECO_BudgetAssignmentTriggers.calculateMultiplier(trigger.new);
            }catch(Exception e){
                system.debug('Graham is lame');
            }
        }
*/        
    }
}