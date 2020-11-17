/**
 * Created by Pavel Lapitski on 2020-05-08.
 */
@RestResource(UrlMapping='/Invoice/*')
global with sharing class InvoiceWebService {
    
    @HttpPatch
    global static InvoiceResponse createInvoice() {
        InvoiceResponse restResponse = new InvoiceResponse();

        // Content-Type = application/json
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;

        // prepare data for invoice xero callout

        /*System.debug('### res: ' + res);

        Record data = null;
        try {
            //System.debug('### body: ' + req.requestBody.toString());
            data = (Record) JSON.deserializeStrict(req.requestBody.toString(), Record.class);
        } catch (JSONException jsonEx) {
            restResponse.error(InvoiceWebServiceResponse.INTERNAL_SERVER_ERROR, res, jsonEx.getMessage());
        } catch (Exception ex) {
            restResponse.error(InvoiceWebServiceResponse.INTERNAL_SERVER_ERROR, res, ex.getMessage());
        }

        if (data == null) return restResponse;

        try {
            insert InvoiceHelper.setInvoice(data);
            restResponse.success(InvoiceWebServiceResponse.OK, res);
        } catch (Exception ex) {
            restResponse.error(InvoiceWebServiceResponse.INTERNAL_SERVER_ERROR, res, ex.getMessage());
        }*/



        // do a callout invoice
        /*List<XeroSync.InvoiceWrapper> responses = sendInvoice(data);
        for (XeroSync.InvoiceWrapper response :responses) {
            if (response.status.equals(XeroSync.STATUS_SUCCESS)) {
                restResponse.success(InvoiceWebServiceResponse.OK, res);
            } else {
                restResponse.error(InvoiceWebServiceResponse.INTERNAL_SERVER_ERROR, res, response.message);
            }
        }*/

        // create and insert record if needed?

        // return a response
        return restResponse;

        /*String extId = req.requestURI.substring(req.requestURI.lastIndexOf('/') + 1);
        Map<String, Object> jsonMap = (Map<String, Object>) JSON.deserializeUntyped(req.requestBody.toString());
        if (nullOrBlank(jsonMap,'id') && String.isBlank(extId)) {
            restResponse.error(KevinServiceResponse.BAD_REQUEST, res, 'Id is blank');
        } else if (jsonMap.containsKey('id') && String.isNotBlank(extId) && (jsonMap.get('id') != extId)) {
            restResponse.errorWLogForOrg(KevinServiceResponse.BAD_REQUEST, res, 'Ids are different', extId);
        } else {
            extId = String.isBlank(extId) ? String.valueOf(jsonMap.get('id')) : extId;
            SObject kevOrg = KevinOrganizationDAO.getRecord(extId);
            if (kevOrg == null) {
                restResponse.errorWLogForOrg(KevinServiceResponse.NO_CONTENT, res, 'Record doesn\'t exist', extId);
            } else {
                try {
                    Entity kevOrgRecord = (Entity) JSON.deserialize(
                            req.requestBody.toString().replace('"id"', '"extId"'),
                            Entity.class
                    );
                    KevinOrganizationDAO.updateRecord(kevOrgRecord.convertToSObject());
                    restResponse.success(KevinServiceResponse.OK, res, null);
                } catch (Exception ex) {
                    restResponse.errorWLogForOrg(KevinServiceResponse.INTERNAL_SERVER_ERROR, res, ex.getMessage(), extId);
                }
            }
        }*/
    }

    global class InvoiceResponse extends InvoiceWebServiceResponse {
        //global Entity record { get; set; }

        public void success(Integer statusCode, System.RestResponse res, Object record) {
            this.status = Statuses.SUCCESS.name();
            res.statusCode = statusCode;
            // this.record = (Entity) record;
        }
    }

    /*global class Entity {
        public String extId { get; set; }
        public String name { get; set; }
    }*/

    public class Project {
        public String type { get; set; } // month/lifetime
        public String billingProfile { get; set; }
        public String marginType { get; set; }
        public String paymentType { get; set; }
        public String project { get; set; }
        public String contract { get; set; }
        public Date invoiceMonth { get; set; }
        public Boolean isInstantRebate { get; set; }
        public Integer delivered { get; set; }
        public Integer ordered { get; set; }
        public Decimal clientSpend { get; set; }
        public Decimal invoiceAmount { get; set; }
        public Decimal margin { get; set; }
        public Decimal maxCPA { get; set; }
        public Decimal mediaOrder { get; set; }
        public Decimal mediaSpend { get; set; }
        public Decimal rebateRate { get; set; }
    }

    public class Campaign {
        public String invoiceLayout { get; set; } // is taken from Account: "Single Item", "Media/Strike Fee"
        public String name { get; set; }
        public String clientIO { get; set; }      // i.e. "013381" or "O-L1D3"
        public String po { get; set; }            // "PO #"
        public String region { get; set; }        // is taken from Account.Region__c: APAC/EMEA/NA
    }

    public class Xero {
        public String xeroAccount { get; set; } 	// "Strike Exchange LLC.", "Strike Exchange Ltd. GB", "Strike Exchange Pte. Ltd."
        public XeroContract contact { get; set; }
        public String xeroId { get; set; }        // External Id: "6617ae81-c1e4-4c6d-90a0-852f9a08496a"
        public String itemCode { get; set; } 		// "Media Cost", "Service Fee's"
    }

    public class XeroContract {
        public Boolean isNew { get; set; }         // true - if need to created a new contact in xero
        public String name { get; set; }           // i.e. "Pikoff Attorneys"
        public String email { get; set; }
    }

    public class Record {
        public Project project { get; set; }
        public Campaign campaign { get; set; }
        public Xero xero { get; set; }

        public Record(Project p, Campaign c, Xero x) {
            project = p;
            campaign = c;
            xero = x;
        }
    }

}