({
    onfocus: function(cmp, event, helper) {
        var getInputkeyWord = cmp.get("v.searchKeyWord");
        if (getInputkeyWord && getInputkeyWord.length > 0) {
            helper.showSpinner(cmp);

            helper.showRecordsList(cmp);
            helper.search(cmp, event, getInputkeyWord);
        }
    },

    setFocus: function(cmp) {
        setTimeout(function() {
            cmp.find("inputId").focus();
        }, 100);
    },

    onmouseleave: function(cmp, event, helper) {
        cmp.set("v.listOfSearchRecords", null);

        helper.hideRecordsList(cmp);

        // fire a method if parent exists and the method is defined on parent
        let lookUpChangeEvent = cmp.getEvent("lookUpChangeEvent");
        if (lookUpChangeEvent) {
            lookUpChangeEvent.setParams({"noChanges": true});
            lookUpChangeEvent.fire();

            // if the event is not going to bubble up from the source component to the application root, the value won't be equal to 'Bubble'
            // in other words, if method is not to be run on parent (parent cmp doesn't have event handler defined), "hideLookupField" won't be called
            if (lookUpChangeEvent.getPhase() !== undefined && lookUpChangeEvent.getPhase().toLowerCase() == 'buble') {
                helper.hideLookupField(cmp);
            }
        }
    },

    keyPressController: function(cmp, event, helper) {
        let getInputkeyWord = cmp.get("v.searchKeyWord");
        if (getInputkeyWord && getInputkeyWord.length > 0) {
            helper.showRecordsList(cmp);
            helper.search(cmp, event, getInputkeyWord);
        } else {
            cmp.set("v.listOfSearchRecords", null);
            helper.hideRecordsList(cmp);
        }
    },

    selectRecordFromLookupList: function(cmp, event, helper) {
        let selectedRecord = event.getParam("record");
        let fieldToSearch = cmp.get("v.fieldToSearch");

        cmp.set("v.searchKeyWord" , selectedRecord[fieldToSearch]);
        helper.hideRecordsList(cmp);

        let lookUpChangeEvent = cmp.getEvent("lookUpChangeEvent");
        if (lookUpChangeEvent) {
            lookUpChangeEvent.setParams({"record" : selectedRecord, "noChanges": false});
            lookUpChangeEvent.fire();

            //if method is not to be run on parent (parent cmp doesn't have event handler defined), "hideLookupField" won't be called
            if (lookUpChangeEvent.getPhase() !== undefined && lookUpChangeEvent.getPhase().toLowerCase() == 'buble') {
                helper.hideLookupField(cmp);
            }
        }
    },
})