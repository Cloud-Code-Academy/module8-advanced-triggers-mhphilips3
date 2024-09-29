public with sharing class OpportunityTriggerHandler extends TriggerHandler{
    
    private List<Opportunity> newOppList;
    
    public OpportunityTriggerHandler() {
        this.newOppList = (List<Opportunity>)Trigger.new;

    }

    public override void beforeInsert(){
        // Set default Type for new Opportunities
        for (Opportunity opp : newOppList){
            if (opp.Type == null){
                opp.Type = 'New Customer';
            }
        }        
    }
}