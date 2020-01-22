({
    doInit : function(component, event, helper)
    {
        helper.validateAccount(component, event, helper);
    },
    changeAccType : function(component, event, helper) 
    {
        helper.updateAccountToPersonAccount(component, event, helper);
    },
})