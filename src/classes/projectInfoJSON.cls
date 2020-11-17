public class projectInfoJSON {

    // required
    public String salesforce_id { get; set; }
    public String strike_project_id { get; set; }
    public Double client_spend { get;set; }
    public String start_date { get;set; }
    public String end_date { get;set; }

    public String agency {get; set;}
    public String account {get; set;}
    public String agency_name {get; set;}
    public String brand { get; set; } //could be empty
    public String customer_id { get; set; } //could be empty
    public String adwords_account_name { get; set; } //could be empty
    public String fb_account_id { get; set; } //could be empty
    public String dbm_account_id { get; set; } //could be empty
    public String snapchat_account_id { get; set; } //could be empty
    public String pinterest_account_id { get; set; } //could be empty
    public String twitter_account_id { get; set; } //could be empty
    public String linkedin_account_id { get; set; } //could be empty
    public String client_service_email { get; set; } //could be empty
    public String name { get; set; } //could be empty
    public String billing_profile { get; set; } //could be empty
    public String currency_c { get; set; } //could be empty
    public Double margin { get;set; } //could be nil
    public String margin_type { get;set; } //could be nil
    public List<String> geo { get;set; } //could be empty
    public List<String> video_length { get;set; } //could be empty
    public List<String> language { get;set; } //could be empty
    public String last_modified_by {get; set;}
    public String targeting { get; set; } //could be empty
    public Double media_order { get;set; } //could be nil

    public List<VideoUrl> youtube_urls {get; set;}
    public List<String> brand_verticals {get; set;}
    public List<String> verticals {get; set;}

    public String more_info { get;set; } //could be empty

    public String region { get;set; } // null or NA/EMEA/APAC
    public Boolean companion_banner { get;set; } //could be null
    public Boolean tags { get;set; } //could be null
    public List<PlatformJSON> platforms { get;set; } //

    public List<ProjectJSON> payment_plan { get;set; }

    public projectInfoJSON(Project__c contract) {
        salesforce_id           = contract.Id;
        strike_project_id       = contract.Project_ID__c;
        client_spend            = contract.Client_Spend__c;
        start_date              = contract.Start_Date__c != null ? Utility.formatDate(contract.Start_Date__c) : null;
        end_date                = contract.End_Date__c != null ? Utility.formatDate(contract.End_Date__c) : null;
        agency                  = String.isNotBlank(contract.Account__r.Name) ? contract.Account__r.Name : '';
        account                 = String.isNotBlank(contract.Account__r.Name) ? contract.Account__r.Name : '';
        agency_name             = String.isNotBlank(contract.Account__r.Agency__c) ? contract.Account__r.Agency__c : '';
        brand                   = String.isBlank(contract.Brand__r.name) == false ? contract.Brand__r.name : '';
        client_service_email    = (contract.ClientServicesRep__c != null && String.isNotBlank(contract.ClientServicesRep__r.Email)) ? contract.ClientServicesRep__r.Email : '';
        name                    = String.isBlank(contract.Name) == false ? contract.Name : '';
        billing_profile         = contract.Account_Type__c != null ? contract.Account_Type__c : '';
        currency_c              = contract.CurrencyIsoCode != null ? contract.CurrencyIsoCode : '';
        margin                  = contract.Margin__c != null ? contract.Margin__c / 100 : null;
        margin_type             = contract.Margin_Type__c != null ? contract.Margin_Type__c : '';
        geo                     = String.isBlank(contract.Geo__c) == false ? (contract.Geo__c).split(';') : new List<String>();
        video_length            = String.isBlank(contract.Video_Length__c) == false ? (contract.Video_Length__c).split(';') : new List<String>();
        language                = String.isBlank(contract.Language__c) == false ? (contract.Language__c).split(';') : new List<String>();
        last_modified_by        = contract.LastModifiedBy__c!=null?contract.LastModifiedBy__r.Email:contract.LastModifiedBy.Email;
        targeting               = String.isBlank(contract.Targeting__c) == false ? contract.Targeting__c : '';
        media_order             = contract.Media_Order__c != null ? contract.Media_Order__c : null;
        more_info               = String.isBlank(contract.More_Info__c) == false ? contract.More_Info__c : '';
        region                  = String.isBlank(contract.Region__c) == false ? (contract.Region__c).toLowerCase() : null;
        brand_verticals         = String.isNotBlank(contract.Brand__r.Verticals__c) ? (contract.Brand__r.Verticals__c).split(';') : new List<String>();
        verticals               = String.isNotBlank(contract.Verticals__c) ? (contract.Verticals__c).split(';') : new List<String>();

        platforms = new List<PlatformJSON>();

        if (!contract.contractPlatforms__r.isEmpty()) {
            for (OpportunityPlatform__c contrPlatform : contract.ContractPlatforms__r) {
                platforms.add(new PlatformJSON(contrPlatform, contract.ContractAdPlacements__r));

                String platformAccountId = (String.isNotBlank(contrPlatform.PlatformAccount__c)) ? contrPlatform.PlatformAccount__c : '';

                if (contrPlatform.Platform__r.Provider__c == 'Snapchat' && String.isBlank(snapchat_account_id)) {
                    snapchat_account_id = platformAccountId;
                } else if (contrPlatform.Platform__r.Provider__c == 'DBM' && String.isBlank(dbm_account_id)) {
                  dbm_account_id = platformAccountId;
                } else if (contrPlatform.Platform__r.Provider__c == 'Facebook' && String.isBlank(fb_account_id)) {
                    fb_account_id = platformAccountId;
                } else if (contrPlatform.Platform__r.Provider__c == 'Twitter' && String.isBlank(twitter_account_id)) {
                    twitter_account_id = platformAccountId;
                } else if (contrPlatform.Platform__r.Provider__c == 'LinkedIn' && String.isBlank(linkedin_account_id)) {
                    linkedin_account_id = platformAccountId;
                } else if (contrPlatform.Platform__r.Provider__c == 'Pinterest' && String.isBlank(pinterest_account_id)) {
                    pinterest_account_id = platformAccountId;
                } else if (contrPlatform.Platform__r.Provider__c == 'AdWords' && String.isBlank(adwords_account_name)) {
                    adwords_account_name = platformAccountId;
                    customer_id = platformAccountId;
                }
            }
        }

        youtube_urls = new List<VideoUrl>();
        for (VideoUrl__c videoUrl : contract.YouTubeURLs__r) {
            youtube_urls.add(new VideoUrl(videoUrl));
        }

        payment_plan = new List<ProjectJSON>();
        for (Payment__c project : contract.Payments__r) {
            payment_plan.add(new ProjectJSON(project));
        }
    }

    public String getJSONFormat() {
        return JSON.serialize(this);
    }

    /* Project JSON helper class */
    public class ProjectJSON {
        public String project_id { get; set; }
        public String salesforce_id { get;set; }
        public Double client_spend { get;set; }
        public String platform {get; set;}
        public String cost_structure {get; set;}
        public String action_type {get; set;}
        public Boolean brand_lift_study { get; set; }
        public List<String> objectives { get; set; }
        public Boolean no_cost_structure {get; set;}
        public Integer quantity_ordered {get; set;}
        public Double unit_cost {get; set;}
        public String start_date { get; set; }
        public String end_date { get;set; }
        public Boolean is_overlapping {get; set;}
        public Boolean companion_banner { get;set; } //could be null
        public Boolean tags { get;set; } //could be null
        public String cta_overlay_text { get; set; }
        public String facebook_page { get; set; }
        public String kpi { get; set; }
        public List<String> gender { get; set; } //could be empty
        public List<String> age { get;set; } //could be empty

        public ProjectJSON(Payment__c project) {
            project_id        = (String.isNotBlank(project.StrikeId__c) && project.ApplyStrikeIdSuffix__c) ? project.StrikeId__c : project.ProjectID__c;
            salesforce_id     = project.Id;
            client_spend      = project.Client_Spend__c;
            platform          = project.OpportunityPlatform__r.Platform__r.Name;
            cost_structure    = project.CostStructure__c;
            action_type		  = project.Action_Type__c != null ? project.Action_Type__c : '';
            objectives        = String.isNotBlank(project.Objectives__c)? (project.Objectives__c).split(';') : new List<String>();
            no_cost_structure = project.OpportunityPlatform__r.NoCostStructure__c;
            unit_cost         = project.UnitCost__c;
            quantity_ordered  = Integer.valueOf(project.Quantity__c);
            start_date        = Utility.formatDate(project.Start_Date__c);
            end_date          = Utility.formatDate(project.End_Date__c);
            is_overlapping    = project.isOverlapping__c;
            cta_overlay_text  = project.CTA_Overlay_Text__c;
            gender            = String.isNotBlank(project.Gender__c) ? (project.Gender__c).split(';') : new List<String>();
            kpi               = String.isNotBlank(project.KPI__c) ? project.KPI__c : '';
            age               = String.isNotBlank(project.Age__c) ? (project.Age__c).split(';') : new List<String>{project.AgeText__c};
            facebook_page     = project.Facebook_page__c;

            if (project.Companion_Banner__c != null && project.Companion_Banner__c == 'Yes') {
                companion_banner = true;
            } else if (project.Companion_Banner__c != null && project.Companion_Banner__c == 'No') {
                companion_banner = false;
            }

            if (project.Pixel_Tracking__c != null && project.Pixel_Tracking__c == 'Yes') {
                tags = true;
            } else if (project.Pixel_Tracking__c != null && project.Pixel_Tracking__c == 'No') {
                tags = false;
            }
            
            if (project.Brand_Lift_Study__c != null && project.Brand_Lift_Study__c == 'Yes') {
                brand_lift_study = true;
            } else if (project.Brand_Lift_Study__c != null && project.Brand_Lift_Study__c == 'No') {
                brand_lift_study = false;
            }
        }
    }

    public class PlatformJSON {
        public String name {get; set;}
        public List<String> ad_placements {get; set;}

        public PlatformJSON(OpportunityPlatform__c contractPlatform, List<OpportunityAdPlacement__c> contractAdPlacements) {
            this.name = contractPlatform.Platform__r.Name;
            this.ad_placements = new List<String>();

            for (OpportunityAdPlacement__c contrAdPlacement : contractAdPlacements) {
                if (contrAdPlacement.OpportunityPlatform__c == contractPlatform.Salesforce_ID__c) {
                    ad_placements.add(contrAdPlacement.AdPlacement__r.Name);
                }
            }
        }
    }

    public class VideoUrl {
        public string name {get; set;}
        public String youtube_url {get; set;}
        public String click_through_url {get; set;}
        public Boolean is_placeholder {get; set;}
        public String salesforce_id {get; set;}
        public String start_date {get; set;}
        public String end_date {get; set;}
        public Boolean archive {get; set;}
        public String format {get; set;}
        public String text {get; set;}
        public String platform {get; set;}
        public Double rotation {get; set;}

        public VideoUrl(VideoUrl__c url) {
            click_through_url   = String.isNotBlank(url.ClickThroughURL__c) ? url.ClickThroughURL__c : '';
            name                = url.Name;
            youtube_url         = url.Url__c;
            is_placeholder      = url.isPlaceholder__c;
            salesforce_id       = url.Salesforce_ID__c == null ? url.Id : url.Salesforce_ID__c;
            start_date          = url.StartDate__c != null ? Utility.formatDate(url.StartDate__c) : '';
            end_date            = url.EndDate__c != null ? Utility.formatDate(url.EndDate__c) : '';
            archive             = url.Archive__c;
            format              = url.Format__c;
            text                = url.Text__c;
            platform            = url.Platform__c;
            rotation            = url.Rotation__c != null ? url.Rotation__c / 100 : null;
        }
    }
}