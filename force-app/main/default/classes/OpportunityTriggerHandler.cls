public with sharing class OpportunityTriggerHandler extends TriggerHandler{
    
    private List<Opportunity> newOppList;
    private List<Opportunity> oldOppList;
    private Map<Id, Opportunity> oldOppMap;
    
    public OpportunityTriggerHandler() {
        this.newOppList = (List<Opportunity>)Trigger.new;
        this.oldOppList = (List<Opportunity>)Trigger.old;
        this.oldOppMap = (Map<Id, Opportunity>)Trigger.oldMap;

    }

    public override void beforeInsert(){
        // Set default Type for new Opportunities
        for (Opportunity opp : newOppList){
            if (opp.Type == null){
                opp.Type = 'New Customer';
            }
        }        
    }
    public override void beforeDelete(){
        // Prevent deletion of closed Opportunities
        for (Opportunity oldOpp : oldOppList){
            if (oldOpp.IsClosed){
                oldOpp.addError('Cannot delete closed opportunity');
            }
        }
    }
    public override void beforeUpdate(){
        // Append Stage changes in Opportunity Description
        for (Opportunity opp : newOppList){                
            if (opp.StageName != null && opp.StageName != oldOppMap.get(opp.Id).StageName){
                opp.Description += '\n Stage Change:' + opp.StageName + ':' + DateTime.now().format();
            }                                
        }
    }
    public override void afterInsert(){
        // Create a new Task for newly inserted Opportunities
        List<Task> taskList = new List<Task>();
        for (Opportunity opp : newOppList){
            Task tsk = new Task();
            tsk.Subject = 'Call Primary Contact';
            tsk.WhatId = opp.Id;
            tsk.WhoId = opp.Primary_Contact__c;
            tsk.OwnerId = opp.OwnerId;
            tsk.ActivityDate = Date.today().addDays(3);
            taskList.add(tsk);
        }
        insert taskList;
    }
    public override void afterDelete(){
        // Sends an email notification to the owner of the Opportunity when it gets deleted.
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        List<Opportunity> oppsWithOwnersList = new List<Opportunity>([SELECT Id, OwnerId, Name,
                                                                    Owner.Email FROM Opportunity WHERE Id IN :oldOppList]);
        for (Opportunity opp : oppsWithOwnersList){
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            List<String> setToAddresses = new List<String>{opp.Owner.Email};
            mail.setToAddresses(setToAddresses);
            mail.setSubject('Opportunity Deleted : ' + opp.Name);
            mail.setPlainTextBody('Your Opportunity: ' + opp.Name +' has been deleted.');
            mails.add(mail);
        }        
        
        try {
            Messaging.sendEmail(mails);
        } catch (Exception e){
            System.debug('Exception: ' + e.getMessage());
        }
    }

}