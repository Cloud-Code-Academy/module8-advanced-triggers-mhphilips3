public with sharing class OpportunityTriggerHandler extends TriggerHandler{
    
    private List<Opportunity> newOppList;
    private List<Opportunity> oldOppList;
    
    public OpportunityTriggerHandler() {
        this.newOppList = (List<Opportunity>)Trigger.new;
        this.oldOppList = (List<Opportunity>)Trigger.old;

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
}