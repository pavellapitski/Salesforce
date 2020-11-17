({
    close: function(cmp) {
        let helper = this;
        helper.clearErrors(cmp);

        $A.get("e.force:closeQuickAction").fire()
    },

    showSpinner: function(cmp) {
        cmp.set('v.showSpinner', true);

        cmp.find('connect-btn').set("v.disabled", true);
        cmp.find('create-btn').set("v.disabled", true);
        cmp.find('disconnect-btn').set("v.disabled", true);
        cmp.find('displayXero-btn').set("v.disabled", true);
        cmp.find('connectXero-btn').set("v.disabled", true);
    },

    hideSpinner: function(cmp) {
        cmp.set('v.showSpinner', false);

        cmp.find('connect-btn').set("v.disabled", false);
        cmp.find('create-btn').set("v.disabled", false);
        cmp.find('disconnect-btn').set("v.disabled", false);
        cmp.find('displayXero-btn').set("v.disabled", false);
        cmp.find('connectXero-btn').set("v.disabled", false);
    },

    doInit: function(cmp) {
        let helper = this;
        helper.clearErrors(cmp);

        let recordId = cmp.get('v.recordId');
        let fetchContractAction = cmp.get("c.fetchContract");

        fetchContractAction.setParams({'recordId': recordId});
        helper.showSpinner(cmp);
        fetchContractAction.setCallback(this, function(response) {
            let state = response.getState();
            helper.hideSpinner(cmp);
            if (state === "SUCCESS") {
                cmp.set('v.contract', response.getReturnValue());
            } else {
                cmp.set('v.errorDetails', [response.getError()[0].message]);
                console.error(response.getError()[0].message);
            }
        });
        $A.enqueueAction(fetchContractAction);
    },

    refreshXeroContacts: function(cmp, xeroEntityId) {
        let helper = this;
        helper.clearErrors(cmp);
        helper.showSpinner(cmp);

        let actualiseXeroContactAction = cmp.get("c.actualiseXeroContact");
        actualiseXeroContactAction.setParams({'xeroEntityId': xeroEntityId});
        actualiseXeroContactAction.setCallback(this, function(response) {
            let state = response.getState();
            helper.hideSpinner(cmp);
            if (state === "SUCCESS") {
                cmp.set("v.isXeroEntitySelected", true);
            } else {
                cmp.set('v.errorDetails', [response.getError()[0].message]);
            }
        });
        $A.enqueueAction(actualiseXeroContactAction);
    },

    getXeroContactInfo: function(cmp, xeroId, xeroSettingId) {
        let helper = this;
        helper.clearErrors(cmp);
        helper.showSpinner(cmp);

        let getXeroContactInfoAction = cmp.get("c.getXeroContactInfo");
        getXeroContactInfoAction.setParams({'xeroSettingId': xeroSettingId, 'xeroId': xeroId});
        getXeroContactInfoAction.setCallback(this, function(response) {
            let state = response.getState();
            helper.hideSpinner(cmp);
            if (state === "SUCCESS") {
                let xeroContact = response.getReturnValue();
                cmp.set('v.xeroContact', xeroContact);
            } else {
                cmp.set('v.errorDetails', [response.getError()[0].message]);
            }
        });
        $A.enqueueAction(getXeroContactInfoAction);
    },

    showCustomLookup: function(cmp, lookupId) {
        $A.util.removeClass(cmp.find(lookupId), "slds-hide");
        $A.util.addClass(cmp.find(lookupId), "slds-show");
    },

    hideCustomLookup: function(cmp, lookupId) {
        cmp.set("v.xeroContactName", "");
        $A.util.removeClass(cmp.find(lookupId), "slds-show");
        $A.util.addClass(cmp.find(lookupId), "slds-hide");
    },

    connect: function(cmp) {
        let helper = this;
        helper.clearErrors(cmp);
        helper.showSpinner(cmp);

        let contract = cmp.get('v.contract');
        let xeroContactId = cmp.get('v.xeroContact.ContactID');
        let xeroSettingId = cmp.find("xeroEntity").get('v.value');

        let establishXeroConnectionAction = cmp.get("c.establishXeroConnection");
        establishXeroConnectionAction.setParams({'contractJSON': JSON.stringify(contract), 'xeroContactId': xeroContactId, 'xeroSettingId': xeroSettingId});
        establishXeroConnectionAction.setCallback(this, function(response) {
            let state = response.getState();
            helper.hideSpinner(cmp);
            if (state === "SUCCESS") {
                let auraResponse = response.getReturnValue();
                if (auraResponse.isSuccess === true) {
                    helper.close(cmp);
                    helper.showToast('Record has been linked.', 'success');
                    helper.refreshWithDelay(500);
                } else {
                    cmp.set('v.errorDetails', [auraResponse.errorMsg]);
                }
            } else {
                cmp.set('v.errorDetails', [response.getError()[0].message]);
            }
        });
        $A.enqueueAction(establishXeroConnectionAction);
    },

    disconnect: function(cmp) {
        let helper = this;
        let contract = cmp.get('v.contract');
        helper.clearErrors(cmp);
        helper.showSpinner(cmp);

        let unlinkXeroConnectionAction = cmp.get("c.unlinkXeroConnection");
        unlinkXeroConnectionAction.setParams({'contractJSON': JSON.stringify(contract)});
        unlinkXeroConnectionAction.setCallback(this, function(response) {
            let state = response.getState();
            helper.hideSpinner(cmp);
            if (state === "SUCCESS") {
                let auraResponse = response.getReturnValue();
                console.log('## auraResponse: ', auraResponse);
                if (auraResponse.isSuccess === true) {
                    helper.close(cmp);
                    helper.showToast('Record has been unlinked.', 'success');
                    helper.refreshWithDelay(500);
                } else {
                    cmp.set('v.errorDetails', [auraResponse.errorMsg]);
                }
            } else {
                cmp.set('v.errorDetails', [response.getError()[0].message]);
            }
        });
        $A.enqueueAction(unlinkXeroConnectionAction);
    },

    create: function(cmp) {
        let helper = this;
        let newName = cmp.get('v.xeroRecordName');
        let newEmail = cmp.get('v.xeroRecordEmail');
        let contract = cmp.get('v.contract');
        let errors = [];

        helper.clearErrors(cmp);
        let emailField = cmp.find('emailFieldId');
        if (!emailField.get('v.validity').valid || $A.util.isEmpty(newEmail)) {
            errors.push('Email is not valid.');
            //Shows the help message if the form control is in an invalid state.
            emailField.showHelpMessageIfInvalid();
        }
        let nameField = cmp.find('nameFieldId');
        if ($A.util.isEmpty(newName)) {
            errors.push('Required fields must be completed.');
            nameField.showHelpMessageIfInvalid();

        }
        if (errors && errors.length > 0) {
            cmp.set('v.errorDetails', errors);
            return;
        }

        helper.showSpinner(cmp);
        let createXeroRecordAction = cmp.get("c.createXeroRecord");
        createXeroRecordAction.setParams({'newName': newName, 'newEmail': newEmail, 'contractJSON': JSON.stringify(contract)});
        createXeroRecordAction.setCallback(this, function(response) {
            let state = response.getState();
            helper.hideSpinner(cmp);
            if (state === "SUCCESS") {
                let auraResponse = response.getReturnValue();
                if (auraResponse.isSuccess === true) {
                    helper.close(cmp);
                    helper.showToast('Contact has been successfully created in Xero', 'success');
                    helper.refreshWithDelay(500);
                } else {
                    cmp.set('v.errorDetails', [auraResponse.errorMsg]);
                }
            } else {
                cmp.set('v.errorDetails', [response.getError()[0].message]);
            }
        });
        $A.enqueueAction(createXeroRecordAction);
    },

    showToast: function(msg, toastType) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            title : 'Message',
            message: msg,
            duration:' 5000',
            key: 'info_alt',
            type: toastType,
            mode: 'dismissible'
        });
        toastEvent.fire();
    },

    refreshWithDelay: function(delay) {
        delay = (delay) ? delay : 500;
        setTimeout(function() {
            $A.get('e.force:refreshView').fire();
        }, delay);
    },

    clearErrors: function(cmp) {
        cmp.set('v.errorDetails', []);
    },

})