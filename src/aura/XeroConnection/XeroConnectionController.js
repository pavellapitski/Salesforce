({
    closeClick: function(cmp, event, helper) {
        helper.close(cmp);
    },

    connectXeroClick: function(cmp, event, helper) {
        cmp.set('v.showConnectionSection', true);
    },

    disconnectClick: function(cmp, event, helper) {
        helper.disconnect(cmp);
    },

    connectClick: function(cmp, event, helper) {
        helper.connect(cmp);
    },

    createClick: function(cmp, event, helper) {
        helper.create(cmp);
    },

    displayXeroContactClick: function(cmp, event, helper) {
        helper.getXeroContactInfo(cmp, cmp.get('v.contract.xeroId'), cmp.get('v.contract.xeroEntityId'));
    },

    doInit: function(cmp, event, helper) {
        helper.doInit(cmp);
    },

    onXeroEntitySelect: function(cmp, event, helper) {
        let xeroEntityId = event.getSource().get("v.value");
        cmp.set('v.contract.xeroEntityId', xeroEntityId);

        helper.refreshXeroContacts(cmp, xeroEntityId);
    },

    lookUpChangeEvent: function(cmp, event, helper) {
        let newLookupRecord = event.getParam("record");
        // if noChanges is true, do nothing, it happens on "onmouseleave" event
        // otherwise set a new record from lookup to a main record relation
        if (event.getParam("noChanges") === false && newLookupRecord !== undefined) {
            let xeroSettingId = cmp.find("xeroEntity").get('v.value');

            let fieldsInRecord = cmp.get('v.fieldsToSOQL');
            helper.getXeroContactInfo(cmp, newLookupRecord[fieldsInRecord[0]], xeroSettingId);

            cmp.set('v.showConnectButton', true);
        } else {
            // any handlers needed?
        }
    },

    onNewXeroContactChange: function(cmp, event, helper) {
        // reset input values
        cmp.set('v.xeroRecordName', '');
        cmp.set('v.xeroRecordEmail', '');
        cmp.set('v.xeroContact', null);
        cmp.set("v.xeroContactName", "");

        // hide connect button
        cmp.set('v.showConnectButton', false);

        let doCreteNewXeroContact = event.getSource().get("v.value");
        if (doCreteNewXeroContact) {
            helper.hideCustomLookup(cmp, "customLookup");
        } else {
            helper.showCustomLookup(cmp, "customLookup");
        }
    },
})