({
    search: function(cmp, event, getInputkeyWord) {
        let helper = this;
        let fetchLookUpValuesAction = cmp.get("c.fetchLookUpValues");
        fetchLookUpValuesAction.setParams({
            'searchKeyWord': getInputkeyWord,
            'objectAPIName': cmp.get("v.objectAPIName"),
            'fieldToSearch': cmp.get("v.fieldToSearch"),
            'fieldsToSOQL': cmp.get("v.fieldsToSOQL")
        });

        fetchLookUpValuesAction.setCallback(this, function(response) {
            helper.hideSpinner(cmp);
            let state = response.getState();
            if (state === "SUCCESS") {
                let relatedRecords = response.getReturnValue();
                if (relatedRecords.length == 0) {
                    cmp.set("v.message", 'No Result Found...');
                } else {
                    cmp.set("v.message", '');
                }
                cmp.set("v.listOfSearchRecords", relatedRecords);
            }
        });
        $A.enqueueAction(fetchLookUpValuesAction);
    },

    hideSpinner: function(cmp) {
        $A.util.removeClass(cmp.find("mySpinner"), "slds-show");
    },

    showSpinner: function(cmp) {
        $A.util.addClass(cmp.find("mySpinner"), "slds-show");
    },

    hideRecordsList: function(cmp) {
        let forclose = cmp.find("searchRes");
        $A.util.addClass(forclose, 'slds-is-close');
        $A.util.removeClass(forclose, 'slds-is-open');
    },

    showRecordsList: function(cmp) {
        let forOpen = cmp.find("searchRes");
        $A.util.addClass(forOpen, 'slds-is-open');
        $A.util.removeClass(forOpen, 'slds-is-close');
    },

    hideLookupField: function(cmp) {
        let lookUpField = cmp.find("lookupField");
        $A.util.addClass(lookUpField, 'slds-hide');
        $A.util.removeClass(lookUpField, 'slds-show');
    }
})