public class AuraResponse {
    @AuraEnabled public String errorMsg { get; set; }
    @AuraEnabled public Boolean isSuccess { get {
        return String.isBlank(errorMsg);
    }}
}